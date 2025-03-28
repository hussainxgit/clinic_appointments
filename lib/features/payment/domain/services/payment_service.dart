import '../../data/models/payment_record.dart';
import '../../data/services/myfatoorah_service.dart';
import '../../../messaging/services/sms_service.dart';
import '../../../messaging/domain/entities/sms_message.dart';
import '../../../appointment/data/appointment_repository.dart';
import '../../../patient/data/patient_repository.dart';
import '../../../../core/utils/result.dart';
import '../../data/config/payment_config.dart';
import 'package:intl/intl.dart';
import '../../../appointment/domain/entities/appointment.dart'
    as appointment_entity;
import '../repositories/payment_repository.dart';

class PaymentService {
  final PaymentRepository _paymentRepository;
  final MyFatoorahService _myFatoorahService;
  final SmsService _smsService;
  final AppointmentRepository _appointmentRepository;
  final PatientRepository _patientRepository;

  PaymentService({
    required PaymentRepository paymentRepository,
    required MyFatoorahService myFatoorahService,
    required SmsService smsService,
    required AppointmentRepository appointmentRepository,
    required PatientRepository patientRepository,
  }) : _paymentRepository = paymentRepository,
       _myFatoorahService = myFatoorahService,
       _smsService = smsService,
       _appointmentRepository = appointmentRepository,
       _patientRepository = patientRepository;

  Future<Result<PaymentRecord>> createPaymentForAppointment({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required double amount,
    String currency = 'KWD',
  }) async {
    try {
      // Check if payment already exists
      final existingPayments = await _paymentRepository
          .getPaymentsByAppointment(appointmentId);
      if (existingPayments.isNotEmpty) {
        final latestPayment = existingPayments.first;
        if (latestPayment.status == PaymentStatus.successful) {
          return Result.success(latestPayment);
        } else if (latestPayment.status == PaymentStatus.pending) {
          return Result.success(latestPayment);
        }
      }

      // Create new payment record
      final newPayment = PaymentRecord(
        id: '', // Will be filled by Firestore
        appointmentId: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        amount: amount,
        currency: currency,
        status: PaymentStatus.pending,
        paymentMethod: 'myfatoorah',
        createdAt: DateTime.now(),
      );

      final savedPayment = await _paymentRepository.createPayment(newPayment);
      return Result.success(savedPayment);
    } catch (e) {
      return Result.failure('Failed to create payment: $e');
    }
  }

  Future<Result<PaymentRecord>> generatePaymentLink(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        return Result.failure('Payment not found');
      }

      // Get patient details
      final patient = await _patientRepository.getById(payment.patientId);
      if (patient == null) {
        return Result.failure('Patient not found');
      }

      // Get appointment details for reference
      final appointment = await _appointmentRepository.getById(
        payment.appointmentId,
      );
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }

      // Create invoice link
      final response = await _myFatoorahService.createInvoiceLink(
        appointmentId: payment.appointmentId,
        patientName: patient.name,
        patientEmail: patient.email ?? 'noemail@example.com',
        patientMobile: patient.phone,
        amount: payment.amount,
        currency: payment.currency,
      );

      if (!response.success) {
        return Result.failure(
          response.errorMessage ?? 'Failed to generate payment link',
        );
      }

      // Update payment record with invoice details
      final updatedPayment = payment.copyWith(
        invoiceId: response.invoiceId,
        paymentLink: response.invoiceUrl,
        metadata: {
          ...payment.metadata ?? {},
          'invoiceCreatedAt': DateTime.now().toIso8601String(),
          'myFatoorahPaymentId': response.paymentId,
        },
      );

      final savedPayment = await _paymentRepository.updatePayment(
        updatedPayment,
      );
      return Result.success(savedPayment);
    } catch (e) {
      return Result.failure('Failed to generate payment link: $e');
    }
  }

  Future<Result<bool>> sendPaymentLinkViaWhatsApp(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        return Result.failure('Payment not found');
      }

      if (payment.paymentLink == null) {
        return Result.failure('Payment link not generated yet');
      }

      // Get patient details
      final patient = await _patientRepository.getById(payment.patientId);
      if (patient == null) {
        return Result.failure('Patient not found');
      }

      // Get appointment details for the message
      final appointment = await _appointmentRepository.getById(
        payment.appointmentId,
      );
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }

      // Format appointment date
      final dateFormat = DateFormat('EEEE, MMMM d, yyyy - h:mm a');
      final formattedDate = dateFormat.format(appointment.dateTime);

      // Create WhatsApp message
      final messageText = PaymentConfig.paymentMessageTemplate(
        patientName: patient.name,
        appointmentDate: formattedDate,
        amount: '${payment.amount.toStringAsFixed(3)} ${payment.currency}',
        paymentLink: payment.paymentLink!,
      );

      final whatsappMessage = SmsMessage(
        to: patient.phone,
        from: '', // Will be filled by provider
        body: messageText,
        metadata: {
          'isWhatsApp': true,
          'paymentId': payment.id,
          'appointmentId': payment.appointmentId,
        },
      );

      // Send via Twilio WhatsApp
      final messageResponse = await _smsService.sendSms(
        whatsappMessage,
        providerId: 'twilio',
      );

      if (!messageResponse.success) {
        return Result.failure(
          'Failed to send WhatsApp message: ${messageResponse.errorMessage}',
        );
      }

      // Update payment record as link sent
      final updatedPayment = payment.copyWith(
        linkSent: true,
        metadata: {
          ...payment.metadata ?? {},
          'linkSentAt': DateTime.now().toIso8601String(),
        },
      );

      await _paymentRepository.updatePayment(updatedPayment);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to send payment link: $e');
    }
  }

  Future<Result<PaymentStatus>> checkPaymentStatus(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);
      if (payment == null) {
        return Result.failure('Payment not found');
      }

      if (payment.invoiceId == null) {
        return Result.failure('No invoice ID associated with this payment');
      }

      final response = await _myFatoorahService.checkPaymentStatus(
        payment.invoiceId!,
      );
      if (!response.success) {
        return Result.failure(
          response.errorMessage ?? 'Failed to check payment status',
        );
      }

      // If status has changed, update the payment record
      if (response.status != payment.status) {
        await _paymentRepository.updatePaymentStatus(
          payment.id,
          response.status,
          transactionId: response.transactionId,
        );

        // If payment is successful, update the appointment payment status
        if (response.status == PaymentStatus.successful) {
          await _updateAppointmentPaymentStatus(payment.appointmentId);
          await _sendPaymentConfirmation(payment);
        }
      }

      return Result.success(response.status);
    } catch (e) {
      return Result.failure('Error checking payment status: $e');
    }
  }

  Future<void> _updateAppointmentPaymentStatus(String appointmentId) async {
    try {
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) return;

      // Update the appointment's payment status
      final updatedAppointment = appointment.copyWith(
        paymentStatus:
            appointment_entity
                .PaymentStatus
                .paid, // Use your appointment's payment status enum
      );

      await _appointmentRepository.update(updatedAppointment);
    } catch (e) {
      print('Error updating appointment payment status: $e');
    }
  }

  Future<void> _sendPaymentConfirmation(PaymentRecord payment) async {
    try {
      // Get patient details
      final patient = await _patientRepository.getById(payment.patientId);
      if (patient == null) return;

      // Get appointment details
      final appointment = await _appointmentRepository.getById(
        payment.appointmentId,
      );
      if (appointment == null) return;

      // Format appointment date
      final dateFormat = DateFormat('EEEE, MMMM d, yyyy - h:mm a');
      final formattedDate = dateFormat.format(appointment.dateTime);

      // Create confirmation message
      final messageText = PaymentConfig.paymentConfirmationTemplate(
        patientName: patient.name,
        appointmentDate: formattedDate,
        amount: '${payment.amount.toStringAsFixed(3)} ${payment.currency}',
      );

      final whatsappMessage = SmsMessage(
        to: patient.phone,
        from: '', // Will be filled by provider
        body: messageText,
        metadata: {
          'isWhatsApp': true,
          'type': 'payment_confirmation',
          'paymentId': payment.id,
          'appointmentId': payment.appointmentId,
        },
      );

      // Send via WhatsApp
      await _smsService.sendSms(whatsappMessage, providerId: 'twilio');
    } catch (e) {
      print('Error sending payment confirmation: $e');
    }
  }
}
