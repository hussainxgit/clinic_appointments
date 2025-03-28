"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.myFatoorahWebhook = void 0;
const functions = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
admin.initializeApp();
exports.myFatoorahWebhook = functions.onRequest(async (req, res) => {
    var _a, _b, _c, _d;
    const invoiceId = req.query.Id;
    const invoiceStatus = req.query.Status;
    const paymentId = req.query.paymentId;
    console.log('Received webhook:', { invoiceId, invoiceStatus, paymentId });
    if (!invoiceId) {
        res.status(400).send('Missing invoice ID');
        return;
    }
    try {
        const paymentSnapshot = await admin
            .firestore()
            .collection('payments')
            .where('invoiceId', '==', invoiceId)
            .limit(1)
            .get();
        if (paymentSnapshot.empty) {
            res.status(404).send('Payment record not found');
            return;
        }
        const paymentDoc = paymentSnapshot.docs[0];
        const paymentRecordId = paymentDoc.id;
        const paymentData = paymentDoc.data();
        const newStatus = mapInvoiceStatus(invoiceStatus);
        const transactionId = (_d = (_c = (_b = (_a = req.body) === null || _a === void 0 ? void 0 : _a.Data) === null || _b === void 0 ? void 0 : _b.InvoiceTransactions) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.TransactionId;
        await admin.firestore().runTransaction(async (transaction) => {
            const paymentRef = admin.firestore().collection('payments').doc(paymentRecordId);
            transaction.update(paymentRef, {
                status: newStatus,
                transactionId: transactionId || null,
                completedAt: newStatus === 'successful' ? admin.firestore.FieldValue.serverTimestamp() : null
            });
            if (newStatus === 'successful') {
                const appointmentRef = admin.firestore().collection('appointments').doc(paymentData.appointmentId);
                transaction.update(appointmentRef, { paymentStatus: 'paid' });
            }
        });
        res.redirect(`https://demo.myfatoorah.com/En/KWT/PayInvoice/Result?paymentId=${paymentId || paymentRecordId}`);
    }
    catch (error) {
        console.error('Webhook processing error:', error);
        res.status(500).send('Internal server error');
    }
});
function mapInvoiceStatus(status) {
    const normalizedStatus = status.toLowerCase();
    const statusMap = {
        'paid': 'successful',
        'success': 'successful',
        'unpaid': 'pending',
        'failed': 'failed',
        'expired': 'failed'
    };
    return statusMap[normalizedStatus] || 'pending';
}
//# sourceMappingURL=index.js.map