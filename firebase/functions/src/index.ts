import * as functions from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { Request, Response } from 'express';

// Initialize Firebase Admin
admin.initializeApp();

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

    // Extract InvoiceId from query parameters or body
    const invoiceId = (
      req.query.Id ||
      req.query.paymentId ||
      req.body?.InvoiceId ||
      req.body?.Data?.InvoiceId
    ) as string;

    // Extract status
    const invoiceStatus = (
      req.query.Status ||
      req.body?.InvoiceStatus ||
      req.body?.Data?.InvoiceStatus ||
      'paid' // Default for callback URLs that don't include status
    ) as string;

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
            } as any;
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
      const paymentData = paymentDoc.data() as PaymentRecord;

      console.log(`Found payment record: ${paymentId} with invoiceId: ${paymentData.invoiceId}`);

      // Map MyFatoorah status to our status enum
      const newStatus = mapInvoiceStatus(invoiceStatus);

      // Only update if status has changed meaningfully
      if (shouldUpdateStatus(paymentData.status, newStatus)) {
        // Extract transaction ID if available
        const transactionId = req.body?.Data?.InvoiceTransactions?.[0]?.TransactionId || null;

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
      } else {
        console.log(`No status update needed for payment ${paymentId}`);
      }

      res.status(200).send('OK');
    } catch (error) {
      console.error('Error processing webhook:', error);
      res.status(500).send('Internal Server Error');
    }
  }
);

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
  req: Request
): Promise<void> {
  const paymentRef = admin.firestore().collection('payments').doc(paymentId);

  const updateData: Record<string, any> = {
    status: newStatus,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    metadata: {
      ...(paymentData.metadata || {}),
      webhook: {
        receivedAt: new Date().toISOString(),
        query: req.query,
        body: req.body
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
    // Get the current data to see the structure
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
        paymentStatus: 'paid',
        'status.paymentStatus': 'paid'
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

// Export any additional functions you need here
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
      res.status(200).send({
        success: true,
        status: paymentData?.status,
        updatedAt: paymentData?.lastUpdated
      });
    } catch (error) {
      console.error('Error checking payment status:', error);
      res.status(500).send({ success: false, error: 'Internal server error' });
    }
  }
);