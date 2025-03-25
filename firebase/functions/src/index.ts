import * as functions from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { Request, Response } from 'express';

admin.initializeApp();

// Define types for our payment record
interface PaymentRecord {
    id: string;
    referenceId: string;
    gatewayId: string;
    gatewayPaymentId: string;
    patientId: string;
    amount: number;
    currency: string;
    status: 'pending' | 'successful' | 'failed' | 'unknown';
    transactionId?: string;
    createdAt: admin.firestore.Timestamp | Date;
    updatedAt?: admin.firestore.Timestamp | Date;
    metadata?: Record<string, unknown>;
    errorMessage?: string;
}

// Define appointment type
interface Appointment {
    patientId: string;
    dateTime: admin.firestore.Timestamp | Date;
    paymentStatus: 'pending' | 'paid' | 'failed';
}

// Define patient type
interface Patient {
    phone?: string;
}

/**
 * Webhook handler for MyFatoorah payment callbacks
 */
export const myFatoorahWebhook = functions.onRequest(
    async (req: Request, res: Response): Promise<void> => {
        console.log('Request method:', req.method);
        console.log('Request query:', req.query);

        // Extract InvoiceId from query parameters
        const invoiceId = (req.query.Id || req.query.paymentId) as string;
        const invoiceStatus = 'paid'; // Assume paid for callback URLs

        if (!invoiceId) {
            console.error('Invalid webhook data - no InvoiceId found');
            res.status(400).send('Bad Request: Missing InvoiceId');
            return;
        }

        console.log('Processing payment with InvoiceId:', invoiceId, 'Status:', invoiceStatus);

        const paymentStatus: PaymentRecord['status'] = mapPaymentStatus(invoiceStatus);

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
            const paymentData = paymentDoc.data() as PaymentRecord;

            await admin.firestore().collection('payments').doc(paymentId).update({
                status: paymentStatus,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                metadata: {
                    ...(paymentData.metadata || {}),
                    webhook: {
                        receivedAt: new Date().toISOString(),
                        query: req.query
                    },
                },
            });

            console.log(`Updated payment ${paymentId} status to ${paymentStatus}`);

            if (paymentStatus === 'successful') {
                const appointmentId = paymentData.referenceId;
                const appointmentRef = admin.firestore().collection('appointments').doc(appointmentId);

                const appointmentDoc = await appointmentRef.get();
                if (appointmentDoc.exists) {
                    await appointmentRef.update({
                        paymentStatus: 'paid' as const,
                    });
                    console.log(`Updated appointment ${appointmentId} payment status to paid`);

                    await sendPaymentConfirmation(
                        appointmentDoc.data() as Appointment,
                        paymentData
                    );
                }
            }

            res.status(200).send('OK');
            return;
        } catch (error) {
            console.error('Error processing webhook:', error);
            res.status(500).send('Internal Server Error');
            return;
        }
    }
);

/**
 * Maps MyFatoorah status to internal payment status
 */
function mapPaymentStatus(invoiceStatus: string): PaymentRecord['status'] {
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
async function sendPaymentConfirmation(
    appointmentData: Appointment,
    paymentData: PaymentRecord
): Promise<void> {
    try {
        const patientId = appointmentData.patientId;
        const patientDoc = await admin.firestore().collection('patients').doc(patientId).get();

        if (!patientDoc.exists) return;

        const patient = patientDoc.data() as Patient;
        const patientPhone = patient.phone;

        if (!patientPhone) return;

        const smsRef = admin.firestore().collection('sms_messages').doc();
        await smsRef.set({
            providerId: 'twilio',
            to: patientPhone,
            from: '', // Replace with your Twilio number
            body: `Thank you for your payment of ${paymentData.amount} ${paymentData.currency}. Your appointment on ${new Date(
                appointmentData.dateTime instanceof admin.firestore.Timestamp
                    ? appointmentData.dateTime.toDate()
                    : appointmentData.dateTime
            ).toLocaleDateString()} has been confirmed.`,
            status: 'pending' as const,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`Created SMS notification for patient ${patientId}`);
    } catch (error) {
        console.error('Error sending confirmation notification:', error);
    }
}