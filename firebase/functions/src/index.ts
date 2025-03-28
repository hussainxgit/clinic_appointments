import * as functions from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { Request, Response } from 'express';
import axios from 'axios';

// Initialize Firebase Admin
admin.initializeApp();

// MyFatoorah API configuration
const MYFATOORAH_API_KEY = 'A6mb_CU9MDQuG3bSpC591IMS1UtAQU40Hyt6ba-tlkvxiaWVejiZGDvvyot2X6m4pQsukf6BZsvRxl8qyBWXIbZ-FsmozNRmbLEV5XyvBWC9KNU1Ao3LgTvxIj_lf_RJAiAWfiYch9EV3XI7EE5tEh-V5zCx9GQheS0f40LcCZLSTkxqom0CeeODy65sucz9ae6MxtBOUNszOaevajNNAVMxTNns3mhoxedCnaBqLU-KlbQHUxHfmtIYV8jsG1i2p7mvHSo0NhXTvLbdwuzXldxa0lPWmx4cJiyZzonkf12en6yCiIW_1Yh4mGoMZHTnUIj-25-s4RO153Akvj0d8kmTWXeq5kr_XPAf_icbVkKtFiaSpj9WvrdsEAwBIjqCs-1pqwzWxdHuk9K-i5NjM4wJunv6XmeL85mIH0DHPyscTRAQ28luX_X08Y5P2Dowmg55ER-QNdPt__ip_BCKM4SNeOsyIPsOxaFLI8nukZ-w9SBH4iMgrJ7BefsN64RZ-z_RUqgRMjGcTR4wsinodhG4YghJ-8iNh8LXRTIaQI4Tna_hMIPeDhQlH4D6vHzpL9qqe8RujhAY5JA6RveR8Dsm3zJ8YpEnMU8gfVMHJYDzBhwEZeuZjybPFElf8y5tx203g-HMo6gkxwWz3bdvNI2Nn3alnYt35Z7qhZTKoTIW5EriiwBdTzB4moqWg506GnUcng';
const MYFATOORAH_BASE_URL = "https://apitest.myfatoorah.com"; // Use production URL in production

// Define types for our payment record
interface PaymentRecord {
  id: string;
  appointmentId: string;
  patientId: string;
  doctorId: string;
  amount: number;
  currency: string;
  status: 'pending' | 'successful' | 'failed' | 'cancelled' | 'refunded';
  paymentMethod: string;
  invoiceId?: string;
  transactionId?: string;
  paymentLink?: string;
  linkSent: boolean;
  createdAt: admin.firestore.Timestamp | Date;
  completedAt?: admin.firestore.Timestamp | Date;
  lastUpdated?: admin.firestore.Timestamp | Date;
  metadata?: Record<string, unknown>;
}

/**
 * Webhook handler for MyFatoorah payment callbacks
 */
export const myFatoorahWebhook = functions.onRequest(
  async (req: Request, res: Response): Promise<void> => {
    console.log('Webhook received:', req.method);
    console.log('Request query:', req.query);
    console.log('Request body:', req.body);

    // Extract ID from webhook
    const paymentId = (req.query.paymentId || req.body?.PaymentId)?.toString();

    if (!paymentId) {
      console.error('Invalid webhook data - no payment ID found');
      res.status(400).send('Bad Request: Missing payment ID');
      return;
    }

    try {
      // Query MyFatoorah API directly to get payment status
      const paymentStatusResponse = await getPaymentStatusFromMyFatoorah(paymentId, "PaymentId");

      if (!paymentStatusResponse.IsSuccess) {
        console.error('Error getting payment status from MyFatoorah:', paymentStatusResponse.Message);
        res.status(200).send('OK - Error getting payment status');
        return;
      }

      const invoiceData = paymentStatusResponse.Data;
      const invoiceId = invoiceData.InvoiceId.toString();
      const invoiceStatus = invoiceData.InvoiceStatus;

      console.log(`Got payment status from MyFatoorah: Invoice ID ${invoiceId}, Status: ${invoiceStatus}`);

      // Find payment in our database using the invoice ID
      const paymentDoc = await findPaymentByInvoiceId(invoiceId);

      if (!paymentDoc) {
        console.error(`Payment record for invoice ID ${invoiceId} not found`);
        res.status(200).send('OK - No matching payment found');
        return;
      }

      const dbPaymentId = paymentDoc.id;
      const paymentData = paymentDoc.data() as PaymentRecord;

      // Map MyFatoorah status to our status
      const newStatus = mapInvoiceStatus(invoiceStatus);

      // Only update if status has changed meaningfully
      if (shouldUpdateStatus(paymentData.status, newStatus)) {
        // Find transaction ID if available
        const transactionId = invoiceData.InvoiceTransactions?.[0]?.TransactionId || null;

        // Run a transaction to update all related records
        await admin.firestore().runTransaction(async (transaction) => {
          // 1. Update payment record
          await updatePaymentRecord(transaction, dbPaymentId, paymentData, newStatus, transactionId, invoiceData);

          // 2. If payment successful, update appointment status
          if (newStatus === 'successful') {
            await updateAppointmentStatus(transaction, paymentData.appointmentId);
            // 3. Send confirmation message
            await sendPaymentConfirmation(paymentData);
          }
        });

        console.log(`Payment ${dbPaymentId} updated to ${newStatus}`);
      } else {
        console.log(`No status update needed for payment ${dbPaymentId}`);
      }

      // For GET requests (user redirect), redirect to success page
      if (req.method === 'GET') {
        return res.redirect(`https://demo.myfatoorah.com/En/KWT/PayInvoice/Result?paymentId=${paymentId}`);
      } else {
        // For POST webhooks, return OK
        res.status(200).send('OK');
      }
    } catch (error) {
      console.error('Error processing webhook:', error);
      res.status(200).send('OK - Error processed');
    }
  }
);

/**
 * Query MyFatoorah API directly to get payment status
 */
async function getPaymentStatusFromMyFatoorah(key: string, keyType: string) {
  try {
    const response = await axios.post(
      `${MYFATOORAH_BASE_URL}/v2/GetPaymentStatus`,
      { Key: key, KeyType: keyType },
      {
        headers: {
          'Authorization': `Bearer ${MYFATOORAH_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    return response.data;
  } catch (error) {
    console.error('Error calling MyFatoorah API:', error);
    return { IsSuccess: false, Message: 'Failed to get payment status from MyFatoorah' };
  }
}

/**
 * Find payment by invoice ID
 */
async function findPaymentByInvoiceId(invoiceId: string) {
  // Try to find by invoiceId (exact match)
  const snapshot = await admin
    .firestore()
    .collection('payments')
    .where('invoiceId', '==', invoiceId)
    .limit(1)
    .get();

  if (!snapshot.empty) {
    return snapshot.docs[0];
  }

  // Try to find by invoiceId as string (in case of number vs string mismatch)
  const snapshotStr = await admin
    .firestore()
    .collection('payments')
    .where('invoiceId', '==', invoiceId.toString())
    .limit(1)
    .get();

  if (!snapshotStr.empty) {
    return snapshotStr.docs[0];
  }

  return null;
}

/**
 * Determines if payment status should be updated based on current and new status
 */
function shouldUpdateStatus(currentStatus: string, newStatus: string): boolean {
  // Never downgrade from successful to anything else
  if (currentStatus === 'successful') return false;

  // Always upgrade from pending
  if (currentStatus === 'pending') return true;

  // Upgrade from failed to successful
  if (currentStatus === 'failed' && newStatus === 'successful') return true;

  return false;
}

/**
 * Maps MyFatoorah invoice status to our internal status
 */
function mapInvoiceStatus(invoiceStatus: string): string {
  const status = invoiceStatus.toLowerCase();

  if (status === 'paid' || status === 'success' || status === 'successful') {
    return 'successful';
  } else if (status === 'unpaid' || status === 'pending') {
    return 'pending';
  } else if (status === 'failed' || status === 'expired' || status === 'error') {
    return 'failed';
  } else {
    return 'pending'; // Default to pending for unknown statuses
  }
}

/**
 * Update payment record status in Firestore
 */
async function updatePaymentRecord(
  transaction: admin.firestore.Transaction,
  paymentId: string,
  paymentData: PaymentRecord,
  newStatus: string,
  transactionId: string | null,
  invoiceData: any
): Promise<void> {
  const paymentRef = admin.firestore().collection('payments').doc(paymentId);

  const updateData: Record<string, any> = {
    status: newStatus,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    metadata: {
      ...(paymentData.metadata || {}),
      myfatoorahResponse: {
        receivedAt: new Date().toISOString(),
        invoiceData: invoiceData
      },
    },
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
async function updateAppointmentStatus(
  transaction: admin.firestore.Transaction,
  appointmentId: string
): Promise<void> {
  const appointmentRef = admin.firestore().collection('appointments').doc(appointmentId);
  const appointmentDoc = await appointmentRef.get();

  if (appointmentDoc.exists) {
    // Get the current data
    const currentData = appointmentDoc.data();

    // Try to determine the correct format for payment status
    let updateData: Record<string, any> = {};

    // Check different possible structures for the appointment's payment status field
    if (currentData && 'paymentStatus' in currentData) {
      // Direct field
      updateData.paymentStatus = 'paid';
    } else if (currentData && typeof currentData.paymentStatus === 'string' &&
      currentData.paymentStatus.includes('.')) {
      // Enum string format
      updateData.paymentStatus = 'PaymentStatus.paid';
    } else {
      // Fallback approach
      updateData = {
        paymentStatus: 'paid'
      };
    }

    transaction.update(appointmentRef, updateData);
  } else {
    console.error(`Appointment ${appointmentId} not found`);
  }
}

/**
 * Send a confirmation message to the patient
 */
async function sendPaymentConfirmation(paymentData: PaymentRecord): Promise<void> {
  try {
    const patientId = paymentData.patientId;
    const patientDoc = await admin.firestore().collection('patients').doc(patientId).get();

    if (!patientDoc.exists) {
      console.log(`Patient ${patientId} not found, skipping confirmation message`);
      return;
    }

    const patient = patientDoc.data() as { phone?: string, name?: string };
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
  } catch (error) {
    console.error('Error sending confirmation notification:', error);
    // Don't throw to avoid failing the webhook
  }
}

// Export an endpoint to check payment status manually
export const checkPaymentStatus = functions.onRequest(
  async (req: Request, res: Response): Promise<void> => {
    const paymentId = req.query.paymentId as string;

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

      // If we have an invoiceId, also check with MyFatoorah
      let apiStatus = null;
      if (paymentData?.invoiceId) {
        try {
          const response = await getPaymentStatusFromMyFatoorah(
            paymentData.invoiceId.toString(),
            "InvoiceId"
          );
          if (response.IsSuccess) {
            apiStatus = response.Data.InvoiceStatus;
          }
        } catch (error) {
          console.error('Error checking with MyFatoorah API:', error);
        }
      }

      res.status(200).send({
        success: true,
        status: paymentData?.status,
        apiStatus: apiStatus,
        updatedAt: paymentData?.lastUpdated
      });
    } catch (error) {
      console.error('Error checking payment status:', error);
      res.status(500).send({ success: false, error: 'Internal server error' });
    }
  }
);