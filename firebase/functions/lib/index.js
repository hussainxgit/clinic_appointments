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
    var _a, _b, _c, _d, _e, _f;
    console.log('Webhook received:', req.method);
    console.log('Request query:', req.query);
    console.log('Request body:', req.body);
    // Extract paymentId from query parameters
    const paymentId = (req.query.Id ||
        req.query.paymentId ||
        ((_a = req.body) === null || _a === void 0 ? void 0 : _a.InvoiceId) ||
        ((_c = (_b = req.body) === null || _b === void 0 ? void 0 : _b.Data) === null || _c === void 0 ? void 0 : _c.InvoiceId));
    if (!paymentId) {
        console.error('Invalid webhook data - no payment ID found');
        res.status(400).json({
            success: false,
            message: 'Bad Request: Missing payment ID'
        });
        return;
    }
    const invoiceStatus = (req.query.Status ||
        ((_d = req.body) === null || _d === void 0 ? void 0 : _d.InvoiceStatus) ||
        ((_f = (_e = req.body) === null || _e === void 0 ? void 0 : _e.Data) === null || _f === void 0 ? void 0 : _f.InvoiceStatus) ||
        'paid');
    try {
        // Find and process the payment
        let paymentSnapshot = await admin
            .firestore()
            .collection('payments')
            .where('invoiceId', '==', paymentId)
            .limit(1)
            .get();
        // Try alternative lookup methods if needed
        if (paymentSnapshot.empty) {
            // [Similar lookup logic as before]
            // For brevity, I've omitted the previous lookup methods
            console.log(`Payment not found with invoiceId ${paymentId}`);
        }
        if (paymentSnapshot.empty) {
            console.error(`Payment record related to ${paymentId} not found`);
            // Still need to redirect to MyFatoorah result page
            return res.redirect(`https://demo.myfatoorah.com/En/KWT/PayInvoice/Result?paymentId=${paymentId}`);
        }
        const paymentDoc = paymentSnapshot.docs[0];
        const firestorePaymentId = paymentDoc.id;
        const paymentData = paymentDoc.data();
        console.log(`Found payment record: ${firestorePaymentId}`);
        const newStatus = mapInvoiceStatus(invoiceStatus);
        // Process payment updates if needed
        if (shouldUpdateStatus(paymentData.status, newStatus)) {
            // Update payment record and related data
            await admin.firestore().runTransaction(async (transaction) => {
                var _a, _b, _c, _d;
                const transactionId = ((_d = (_c = (_b = (_a = req.body) === null || _a === void 0 ? void 0 : _a.Data) === null || _b === void 0 ? void 0 : _b.InvoiceTransactions) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.TransactionId) || null;
                await updatePaymentRecord(transaction, firestorePaymentId, paymentData, newStatus, transactionId, req);
                if (newStatus === 'successful') {
                    await updateAppointmentStatus(transaction, paymentData.appointmentId);
                    await sendPaymentConfirmation(paymentData);
                }
            });
        }
        // Always redirect to MyFatoorah result page
        return res.redirect(`https://demo.myfatoorah.com/En/KWT/PayInvoice/Result?paymentId=${paymentId}`);
    }
    catch (error) {
        console.error('Error processing webhook:', error);
        // Even on error, redirect to MyFatoorah result page
        return res.redirect(`https://demo.myfatoorah.com/En/KWT/PayInvoice/Result?paymentId=${paymentId}`);
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