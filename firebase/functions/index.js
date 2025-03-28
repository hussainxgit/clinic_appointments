"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkPaymentStatus = exports.myFatoorahWebhook = void 0;
// firebase/functions/src/index.ts - Complete updated webhook handler
const functions = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();
/**
 * Webhook handler for MyFatoorah payment callbacks
 */
exports.myFatoorahWebhook = functions.onRequest(async (req, res) => {
    var _a, _b, _c, _d, _e, _f;
    console.log('Webhook received:', req.method);
    console.log('Request query:', req.query);
    console.log('Request body:', req.body);
    // Extract InvoiceId from query parameters or body
    // MyFatoorah can send data in different formats
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
    const paymentStatus = mapPaymentStatus(invoiceStatus);
    try {
        // First try to find payment by gateway payment ID
        let paymentSnapshot = await admin
            .firestore()
            .collection('payments')
            .where('gatewayPaymentId', '==', invoiceId)
            .limit(1)
            .get();
        // If no payment found, try to use metadata as fallback
        if (paymentSnapshot.empty) {
            console.log(`Payment record with gatewayPaymentId ${invoiceId} not found, trying alternative lookups...`);
            // Try to find by invoice ID in metadata
            paymentSnapshot = await admin
                .firestore()
                .collection('payments')
                .where('metadata.InvoiceId', '==', invoiceId)
                .limit(1)
                .get();
            // Try with a different case of the field name
            if (paymentSnapshot.empty) {
                paymentSnapshot = await admin
                    .firestore()
                    .collection('payments')
                    .where('metadata.invoiceId', '==', invoiceId)
                    .limit(1)
                    .get();
            }
        }
        if (paymentSnapshot.empty) {
            console.error(`Payment record related to ${invoiceId} not found after all lookup attempts`);
            // Still return 200 to prevent retries
            res.status(200).send('OK - No matching payment found');
            return;
        }
        const paymentDoc = paymentSnapshot.docs[0];
        const paymentId = paymentDoc.id;
        const paymentData = paymentDoc.data();
        console.log(`Found payment record: ${paymentId}`);
        console.log(`Payment record data: ${JSON.stringify(paymentData)}`);
        // Only update if status is better than current
        // (pending -> successful or pending -> failed)
        if (shouldUpdateStatus(paymentData.status, paymentStatus)) {
            await updatePaymentStatus(paymentId, paymentData, paymentStatus, req);
            // If payment was successful, update the appointment
            if (paymentStatus === 'successful') {
                console.log(`Payment successful, referenceId (appointment): ${paymentData.referenceId}`);
                // Start a transaction to ensure both payment and appointment are updated together
                await admin.firestore().runTransaction(async (transaction) => {
                    // Update the appointment status
                    await updateAppointmentStatus(paymentData.referenceId, transaction);
                    // Optionally send confirmation message
                    await sendPaymentConfirmation(paymentData);
                });
            }
        }
        else {
            console.log(`Not updating payment ${paymentId} status from ${paymentData.status} to ${paymentStatus}`);
        }
        res.status(200).send('OK');
        return;
    }
    catch (error) {
        console.error('Error processing webhook:', error);
        res.status(500).send('Internal Server Error');
        return;
    }
});
/**
 * Determines if the payment status should be updated based on current and new status
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
 * Update payment record status in Firestore
 */
async function updatePaymentStatus(paymentId, paymentData, newStatus, req, transaction) {
    console.log(`Updating payment ${paymentId} status from ${paymentData.status} to ${newStatus}`);
    const paymentRef = admin.firestore().collection('payments').doc(paymentId);
    const updateData = {
        status: newStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        metadata: Object.assign(Object.assign({}, (paymentData.metadata || {})), { webhook: {
                receivedAt: new Date().toISOString(),
                query: req.query,
                body: req.body
            } }),
    };
    if (transaction) {
        transaction.update(paymentRef, updateData);
    }
    else {
        await paymentRef.update(updateData);
    }
    console.log(`Updated payment ${paymentId} status to ${newStatus}`);
}
/**
 * Update appointment payment status
 */
async function updateAppointmentStatus(appointmentId, transaction) {
    console.log(`Attempting to update appointment: ${appointmentId}`);
    try {
        const appointmentRef = admin.firestore().collection('appointments').doc(appointmentId);
        const appointmentDoc = await appointmentRef.get();
        if (appointmentDoc.exists) {
            // Get the current data to see the structure
            const currentData = appointmentDoc.data();
            console.log(`Current appointment data: ${JSON.stringify(currentData)}`);
            // Try to determine the correct format for payment status
            // Check how paymentStatus is structured in the appointment
            let updateData = {};
            // Check if appointment has a direct paymentStatus field
            if (currentData && 'paymentStatus' in currentData) {
                console.log('Appointment has direct paymentStatus field');
                updateData.paymentStatus = 'paid';
            }
            // Check if it's an enum string format (like 'PaymentStatus.paid')
            else if (currentData && currentData.paymentStatus && typeof currentData.paymentStatus === 'string' &&
                currentData.paymentStatus.includes('.')) {
                console.log('Appointment uses enum string format');
                updateData.paymentStatus = 'PaymentStatus.paid';
            }
            // Check if it's a nested object
            else if (currentData && currentData.status && typeof currentData.status === 'object' &&
                'paymentStatus' in currentData.status) {
                console.log('Appointment uses nested status object');
                updateData['status.paymentStatus'] = 'paid';
            }
            // Fallback: try multiple approaches
            else {
                console.log('Using fallback approach for appointment update');
                updateData = {
                    paymentStatus: 'paid',
                    'status.paymentStatus': 'paid'
                };
            }
            console.log(`Updating appointment with: ${JSON.stringify(updateData)}`);
            if (transaction) {
                transaction.update(appointmentRef, updateData);
            }
            else {
                await appointmentRef.update(updateData);
            }
            console.log(`Successfully updated appointment ${appointmentId} payment status to paid`);
        }
        else {
            console.error(`Appointment ${appointmentId} not found in Firestore`);
            // Try searching by other fields as fallback
            const appointmentsSnapshot = await admin
                .firestore()
                .collection('appointments')
                .where('referenceId', '==', appointmentId)
                .limit(1)
                .get();
            if (!appointmentsSnapshot.empty) {
                const doc = appointmentsSnapshot.docs[0];
                if (transaction) {
                    transaction.update(doc.ref, { paymentStatus: 'paid' });
                }
                else {
                    await doc.ref.update({ paymentStatus: 'paid' });
                }
                console.log(`Found and updated appointment by referenceId: ${doc.id}`);
            }
            else {
                // Last resort: try to find appointment by exact string match on any field
                console.log('Trying to find appointment by searching all fields');
                const allAppointments = await admin.firestore().collection('appointments').get();
                let foundAppointment = false;
                for (const doc of allAppointments.docs) {
                    const data = doc.data();
                    const stringData = JSON.stringify(data);
                    if (stringData.includes(appointmentId)) {
                        console.log(`Found appointment ${doc.id} containing the reference ID in some field`);
                        if (transaction) {
                            transaction.update(doc.ref, { paymentStatus: 'paid' });
                        }
                        else {
                            await doc.ref.update({ paymentStatus: 'paid' });
                        }
                        foundAppointment = true;
                        break;
                    }
                }
                if (!foundAppointment) {
                    console.error(`Could not find any appointment related to ID: ${appointmentId}`);
                }
            }
        }
    }
    catch (error) {
        console.error(`Error updating appointment ${appointmentId}: ${error}`);
        throw error; // Re-throw to handle in transaction
    }
}
/**
 * Maps MyFatoorah status to internal payment status
 */
function mapPaymentStatus(invoiceStatus) {
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
        return 'unknown';
    }
}
/**
 * Send a confirmation WhatsApp message to patient
 */
async function sendPaymentConfirmation(paymentData) {
    try {
        const patientId = paymentData.patientId;
        console.log(`Sending payment confirmation to patient: ${patientId}`);
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
        // Add WhatsApp confirmation message to the SMS collection
        const smsRef = admin.firestore().collection('sms_messages').doc();
        const messageData = {
            providerId: 'twilio',
            to: patientPhone,
            from: '', // Will be filled by provider
            body: `Thank you ${patientName} for your payment of ${paymentData.amount} ${paymentData.currency}. Your appointment has been confirmed and we look forward to seeing you.`,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: {
                isWhatsApp: true,
                paymentId: paymentData.id,
                appointmentId: paymentData.referenceId
            }
        };
        await smsRef.set(messageData);
        console.log(`Created confirmation SMS for patient ${patientId}: ${smsRef.id}`);
    }
    catch (error) {
        console.error('Error sending confirmation notification:', error);
        // Don't throw the error to avoid failing the whole webhook
    }
}
// Add additional endpoints if needed
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
            updatedAt: paymentData === null || paymentData === void 0 ? void 0 : paymentData.updatedAt
        });
    }
    catch (error) {
        console.error('Error checking payment status:', error);
        res.status(500).send({ success: false, error: 'Internal server error' });
    }
});
//# sourceMappingURL=index.js.map