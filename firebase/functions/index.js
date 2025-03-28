"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkPaymentStatus = exports.myFatoorahWebhook = void 0;
const functions = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
// Initialize Firebase Admin
admin.initializeApp();
/**
 * Webhook handler for MyFatoorah payment callbacks
 */
exports.myFatoorahWebhook = functions.onRequest(async (req, res) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
    console.log('Webhook received:', req.method);
    console.log('Request query:', req.query);
    console.log('Request body:', req.body);
    // Extract InvoiceId from query parameters or body
    const invoiceId = (req.query.Id ||
        req.query.paymentId ||
        ((_a = req.body) === null || _a === void 0 ? void 0 : _a.InvoiceId) ||
        ((_c = (_b = req.body) === null || _b === void 0 ? void 0 : _b.Data) === null || _c === void 0 ? void 0 : _c.InvoiceId));
    // Extract status
    const invoiceStatus = (req.query.Status ||
        ((_d = req.body) === null || _d === void 0 ? void 0 : _d.InvoiceStatus) ||
        ((_f = (_e = req.body) === null || _e === void 0 ? void 0 : _e.Data) === null || _f === void 0 ? void 0 : _f.InvoiceStatus) ||
        'paid' // Default for callback URLs that don't include status
    );
    if (!invoiceId) {
        console.error('Invalid webhook data - no InvoiceId found');
        res.status(400).send('Bad Request: Missing InvoiceId');
        return;
    }
    console.log('Processing payment with InvoiceId:', invoiceId, 'Status:', invoiceStatus);
    try {
        // Try different ways to find the payment record
        let paymentSnapshot = await admin
            .firestore()
            .collection('payments')
            .where('invoiceId', '==', invoiceId)
            .limit(1)
            .get();
        // If not found by invoiceId, try alternative approaches
        if (paymentSnapshot.empty) {
            console.log(`Payment record with invoiceId ${invoiceId} not found, trying metadata...`);
            // Try to find by metadata.myFatoorahPaymentId
            paymentSnapshot = await admin
                .firestore()
                .collection('payments')
                .where('metadata.myFatoorahPaymentId', '==', invoiceId)
                .limit(1)
                .get();
        }
        // Try looking for partial matches in paymentLink
        if (paymentSnapshot.empty) {
            console.log(`Payment not found in metadata, checking pending payments...`);
            // Get all pending payments (usually a small number)
            const pendingSnapshot = await admin
                .firestore()
                .collection('payments')
                .where('status', '==', 'pending')
                .get();
            // Look for invoice ID in the payment link
            for (const doc of pendingSnapshot.docs) {
                const paymentData = doc.data();
                const paymentLink = paymentData.paymentLink || '';
                // Check if the payment link contains part of the invoice ID
                // MyFatoorah often includes part of the ID in the payment URL
                if (invoiceId.includes(paymentData.invoiceId) ||
                    paymentLink.includes(paymentData.invoiceId) ||
                    (paymentData.invoiceId && invoiceId.includes(paymentData.invoiceId))) {
                    console.log(`Found likely match in payment ${doc.id} with invoiceId ${paymentData.invoiceId}`);
                    paymentSnapshot = {
                        docs: [doc],
                        empty: false,
                        // Add these to satisfy TypeScript
                        forEach: () => { },
                        size: 1
                    };
                    break;
                }
            }
        }
        if (paymentSnapshot.empty) {
            console.error(`Payment record related to ${invoiceId} not found after all lookup attempts`);
            res.status(200).send('OK - No matching payment found');
            return;
        }
        const paymentDoc = paymentSnapshot.docs[0];
        const paymentId = paymentDoc.id;
        const paymentData = paymentDoc.data();
        console.log(`Found payment record: ${paymentId} with invoiceId: ${paymentData.invoiceId}`);
        // Map MyFatoorah status to our status enum
        const newStatus = mapInvoiceStatus(invoiceStatus);
        // Only update if status has changed meaningfully
        if (shouldUpdateStatus(paymentData.status, newStatus)) {
            // Extract transaction ID if available
            const transactionId = ((_k = (_j = (_h = (_g = req.body) === null || _g === void 0 ? void 0 : _g.Data) === null || _h === void 0 ? void 0 : _h.InvoiceTransactions) === null || _j === void 0 ? void 0 : _j[0]) === null || _k === void 0 ? void 0 : _k.TransactionId) || null;
            // Run a transaction to update all related records
            await admin.firestore().runTransaction(async (transaction) => {
                // 1. Update payment record
                await updatePaymentRecord(transaction, paymentId, paymentData, newStatus, transactionId, req);
                // 2. If payment successful, update appointment status
                if (newStatus === 'successful') {
                    await updateAppointmentStatus(transaction, paymentData.appointmentId);
                    // 3. Send confirmation message
                    await sendPaymentConfirmation(paymentData);
                }
            });
            console.log(`Payment ${paymentId} updated to ${newStatus}`);
        }
        else {
            console.log(`No status update needed for payment ${paymentId}`);
        }
        res.status(200).send('OK');
    }
    catch (error) {
        console.error('Error processing webhook:', error);
        res.status(500).send('Internal Server Error');
    }
});
/**
 * Determines if payment status should be updated based on current and new status
 */
function shouldUpdateStatus(currentStatus, newStatus) {
    // Never downgrade from successful to anything else
    if (currentStatus === 'successful')
        return false;
    // Always upgrade from pending
    if (currentStatus === 'pending')
        return true;
    // Upgrade from failed to successful
    if (currentStatus === 'failed' && newStatus === 'successful')
        return true;
    return false;
}
/**
 * Maps MyFatoorah invoice status to our internal status
 */
function mapInvoiceStatus(invoiceStatus) {
    const status = invoiceStatus.toLowerCase();
    if (status === 'paid' || status === 'success' || status === 'successful') {
        return 'successful';
    }
    else if (status === 'unpaid' || status === 'pending') {
        return 'pending';
    }
    else if (status === 'failed' || status === 'expired' || status === 'error') {
        return 'failed';
    }
    else {
        return 'pending'; // Default to pending for unknown statuses
    }
}
/**
 * Update payment record status in Firestore
 */
async function updatePaymentRecord(transaction, paymentId, paymentData, newStatus, transactionId, req) {
    const paymentRef = admin.firestore().collection('payments').doc(paymentId);
    const updateData = {
        status: newStatus,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        metadata: Object.assign(Object.assign({}, (paymentData.metadata || {})), { webhook: {
                receivedAt: new Date().toISOString(),
                query: req.query,
                body: req.body
            } }),
    };
    if (newStatus === 'successful') {
        updateData.completedAt = admin.firestore.FieldValue.serverTimestamp();
    }
    if (transactionId) {
        updateData.transactionId = transactionId;
    }
    transaction.update(paymentRef, updateData);
}
/**
 * Update appointment payment status
 */
async function updateAppointmentStatus(transaction, appointmentId) {
    const appointmentRef = admin.firestore().collection('appointments').doc(appointmentId);
    const appointmentDoc = await appointmentRef.get();
    if (appointmentDoc.exists) {
        // Get the current data to see the structure
        const currentData = appointmentDoc.data();
        // Try to determine the correct format for payment status
        let updateData = {};
        // Check different possible structures for the appointment's payment status field
        if (currentData && 'paymentStatus' in currentData) {
            // Direct field
            updateData.paymentStatus = 'paid';
        }
        else if (currentData && typeof currentData.paymentStatus === 'string' &&
            currentData.paymentStatus.includes('.')) {
            // Enum string format
            updateData.paymentStatus = 'PaymentStatus.paid';
        }
        else {
            // Fallback approach
            updateData = {
                paymentStatus: 'paid',
                'status.paymentStatus': 'paid'
            };
        }
        transaction.update(appointmentRef, updateData);
    }
    else {
        console.error(`Appointment ${appointmentId} not found`);
    }
}
/**
 * Send a confirmation message to the patient
 */
async function sendPaymentConfirmation(paymentData) {
    try {
        const patientId = paymentData.patientId;
        const patientDoc = await admin.firestore().collection('patients').doc(patientId).get();
        if (!patientDoc.exists) {
            console.log(`Patient ${patientId} not found, skipping confirmation message`);
            return;
        }
        const patient = patientDoc.data();
        const patientPhone = patient.phone;
        const patientName = patient.name || 'Patient';
        if (!patientPhone) {
            console.log(`Patient ${patientId} has no phone number, skipping confirmation message`);
            return;
        }
        // Get appointment details
        const appointmentDoc = await admin.firestore()
            .collection('appointments')
            .doc(paymentData.appointmentId)
            .get();
        let appointmentDate = 'your appointment';
        if (appointmentDoc.exists) {
            const appointmentData = appointmentDoc.data();
            if (appointmentData && appointmentData.dateTime) {
                // Format date depending on how it's stored
                const date = typeof appointmentData.dateTime === 'string'
                    ? new Date(appointmentData.dateTime)
                    : appointmentData.dateTime.toDate();
                appointmentDate = `${date.toDateString()} at ${date.toLocaleTimeString()}`;
            }
        }
        // Add confirmation message to the SMS collection
        const smsRef = admin.firestore().collection('sms_messages').doc();
        const messageData = {
            providerId: 'twilio',
            to: patientPhone,
            from: '', // Will be filled by provider
            body: `Thank you ${patientName} for your payment of ${paymentData.amount} ${paymentData.currency}. Your appointment on ${appointmentDate} has been confirmed.`,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
                isWhatsApp: true,
                type: 'payment_confirmation',
                paymentId: paymentData.id,
                appointmentId: paymentData.appointmentId
            }
        };
        await smsRef.set(messageData);
    }
    catch (error) {
        console.error('Error sending confirmation notification:', error);
        // Don't throw to avoid failing the webhook
    }
}
// Export any additional functions you need here
exports.checkPaymentStatus = functions.onRequest(async (req, res) => {
    const paymentId = req.query.paymentId;
    if (!paymentId) {
        res.status(400).send({ success: false, error: 'Missing payment ID' });
        return;
    }
    try {
        const paymentDoc = await admin.firestore().collection('payments').doc(paymentId).get();
        if (!paymentDoc.exists) {
            res.status(404).send({ success: false, error: 'Payment not found' });
            return;
        }
        const paymentData = paymentDoc.data();
        res.status(200).send({
            success: true,
            status: paymentData === null || paymentData === void 0 ? void 0 : paymentData.status,
            updatedAt: paymentData === null || paymentData === void 0 ? void 0 : paymentData.lastUpdated
        });
    }
    catch (error) {
        console.error('Error checking payment status:', error);
        res.status(500).send({ success: false, error: 'Internal server error' });
    }
});
//# sourceMappingURL=index.js.map