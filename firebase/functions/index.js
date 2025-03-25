"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.myFatoorahWebhook = void 0;
const functions = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();
/**
 * Webhook handler for MyFatoorah payment callbacks
 */
exports.myFatoorahWebhook = functions.onRequest(async (req, res) => {
    console.log('Request method:', req.method);
    console.log('Request query:', req.query);
    // Extract InvoiceId from query parameters
    const invoiceId = (req.query.Id || req.query.paymentId);
    const invoiceStatus = 'paid'; // Assume paid for callback URLs
    if (!invoiceId) {
        console.error('Invalid webhook data - no InvoiceId found');
        res.status(400).send('Bad Request: Missing InvoiceId');
        return;
    }
    console.log('Processing payment with InvoiceId:', invoiceId, 'Status:', invoiceStatus);
    const paymentStatus = mapPaymentStatus(invoiceStatus);
    try {
        // Search for payment record where a transaction has matching PaymentId
        const paymentSnapshot = await admin
            .firestore()
            .collection('payments')
            .where('metadata.InvoiceTransactions', 'array-contains', {
            PaymentId: invoiceId
        })
            .limit(1)
            .get();
        if (paymentSnapshot.empty) {
            console.error(`Payment record with PaymentId ${invoiceId} not found`);
            res.status(200).send('OK');
            return;
        }
        const paymentDoc = paymentSnapshot.docs[0];
        const paymentId = paymentDoc.id;
        const paymentData = paymentDoc.data();
        await admin.firestore().collection('payments').doc(paymentId).update({
            status: paymentStatus,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            metadata: Object.assign(Object.assign({}, (paymentData.metadata || {})), { webhook: {
                    receivedAt: new Date().toISOString(),
                    query: req.query
                } }),
        });
        console.log(`Updated payment ${paymentId} status to ${paymentStatus}`);
        if (paymentStatus === 'successful') {
            const appointmentId = paymentData.referenceId;
            const appointmentRef = admin.firestore().collection('appointments').doc(appointmentId);
            const appointmentDoc = await appointmentRef.get();
            if (appointmentDoc.exists) {
                await appointmentRef.update({
                    paymentStatus: 'paid',
                });
                console.log(`Updated appointment ${appointmentId} payment status to paid`);
                await sendPaymentConfirmation(appointmentDoc.data(), paymentData);
            }
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
 * Maps MyFatoorah status to internal payment status
 */
function mapPaymentStatus(invoiceStatus) {
    switch (invoiceStatus.toLowerCase()) {
        case 'paid':
            return 'successful';
        case 'unpaid':
            return 'pending';
        case 'failed':
        case 'expired':
            return 'failed';
        default:
            return 'unknown';
    }
}
/**
 * Helper function to send confirmation notification to patient
 */
async function sendPaymentConfirmation(appointmentData, paymentData) {
    try {
        const patientId = appointmentData.patientId;
        const patientDoc = await admin.firestore().collection('patients').doc(patientId).get();
        if (!patientDoc.exists)
            return;
        const patient = patientDoc.data();
        const patientPhone = patient.phone;
        if (!patientPhone)
            return;
        const smsRef = admin.firestore().collection('sms_messages').doc();
        await smsRef.set({
            providerId: 'twilio',
            to: patientPhone,
            from: '', // Replace with your Twilio number
            body: `Thank you for your payment of ${paymentData.amount} ${paymentData.currency}. Your appointment on ${new Date(appointmentData.dateTime instanceof admin.firestore.Timestamp
                ? appointmentData.dateTime.toDate()
                : appointmentData.dateTime).toLocaleDateString()} has been confirmed.`,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Created SMS notification for patient ${patientId}`);
    }
    catch (error) {
        console.error('Error sending confirmation notification:', error);
    }
}
//# sourceMappingURL=index.js.map