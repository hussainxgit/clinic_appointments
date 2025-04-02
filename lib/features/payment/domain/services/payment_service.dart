import '../../data/models/payment_record.dart';
import '../../data/services/myfatoorah_service.dart';
import '../../../messaging/services/kwt_sms_service.dart';
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
  final KwtSmsService _smsService;
  final AppointmentRepository _appointmentRepository;
  final PatientRepository _patientRepository;

  PaymentService({
    required PaymentRepository paymentRepository,
    required MyFatoorahService myFatoorahService,
    required KwtSmsService smsService,
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
      if (existingPayments.data.isNotEmpty) {
        final latestPayment = existingPayments.data.first;
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
      return Result.success(savedPayment.data);
    } catch (e) {
      return Result.failure('Failed to create payment: $e');
    }
  }

  Future<Result<PaymentRecord>> generatePaymentLink(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);

      // Get patient details
      final patient = await _patientRepository.getById(payment.data!.patientId);

      // Create invoice link
      final response = await _myFatoorahService.createInvoiceLink(
        appointmentId: payment.data!.appointmentId,
        patientName: patient.data!.name,
        patientEmail: patient.data!.email ?? 'noemail@example.com',
        patientMobile: patient.data!.phone,
        amount: payment.data!.amount,
        currency: payment.data!.currency,
      );

      if (!response.success) {
        return Result.failure(
          response.errorMessage ?? 'Failed to generate payment link',
        );
      }

      // Update payment record with invoice details
      final updatedPayment = payment.data!.copyWith(
        invoiceId: response.invoiceId,
        paymentLink: response.invoiceUrl,
        metadata: {
          ...payment.data!.metadata ?? {},
          'invoiceCreatedAt': DateTime.now().toIso8601String(),
        },
      );

      final savedPayment = await _paymentRepository.updatePayment(
        updatedPayment,
      );
      return Result.success(savedPayment.data);
    } catch (e) {
      return Result.failure('Failed to generate payment link: $e');
    }
  }

  Future<Result<bool>> sendPaymentLinkViaWhatsApp(String paymentId) async {
    try {
      final payment = await _paymentRepository.getPaymentById(paymentId);

      if (payment.data!.paymentLink == null) {
        return Result.failure('Payment link not generated yet');
      }

      // Get patient details
      final patient = await _patientRepository.getById(payment.data!.patientId);

      // Get appointment details for the message
      final appointment = await _appointmentRepository.getById(
        payment.data!.appointmentId,
      );

      // Format appointment date
      final dateFormat = DateFormat('MMM d, yyyy, h a');
      final formattedDate = dateFormat.format(appointment.data!.dateTime);

      // Create message text
      final messageText = PaymentConfig.paymentMessageTemplate(
        patientName: patient.data!.name,
        appointmentDate: formattedDate,
        amount:
            '${payment.data!.amount.toStringAsFixed(2)} ${payment.data!.currency}',
        paymentLink: payment.data!.paymentLink!,
      );

      // Send SMS using the KWT SMS service
      final result = await _smsService.sendSms(
        phoneNumber: patient.data!.phone,
        message: messageText,
        // For payment links, use English language code by default
        languageCode: 1, // English
      );

      if (result.isFailure) {
        return Result.failure('Failed to send payment link: ${result.error}');
      }

      // Update payment record as link sent
      final updatedPayment =
          payment.data!..copyWith(
            linkSent: true,
            metadata: {
              ...payment.data!.metadata ?? {},
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

      if (payment.data!.invoiceId == null) {
        return Result.failure('No invoice ID associated with this payment');
      }

      final response = await _myFatoorahService.checkPaymentStatus(
        payment.data!.invoiceId!,
      );
      if (!response.success) {
        return Result.failure(
          response.errorMessage ?? 'Failed to check payment status',
        );
      }

      // If status has changed, update the payment record
      if (response.status != payment.data!.status) {
        await _paymentRepository.updatePaymentStatus(
          payment.data!.id,
          response.status,
          transactionId: response.transactionId,
        );

        // If payment is successful, update the appointment payment status
        if (response.status == PaymentStatus.successful) {
          await _updateAppointmentPaymentStatus(payment.data!.appointmentId);
          await _sendPaymentConfirmation(payment.data!);
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

      // Update the appointment's payment status
      final updatedAppointment = appointment.data!.copyWith(
        paymentStatus: appointment_entity.PaymentStatus.paid,
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

      // Get appointment details
      final appointment = await _appointmentRepository.getById(
        payment.appointmentId,
      );

      // Format appointment date
      final dateFormat = DateFormat('EEEE, MMMM d, yyyy - h:mm a');
      final formattedDate = dateFormat.format(appointment.data!.dateTime);

      // Create confirmation message
      final messageText = PaymentConfig.paymentConfirmationTemplate(
        patientName: patient.data!.name,
        appointmentDate: formattedDate,
        amount: '${payment.amount.toStringAsFixed(3)} ${payment.currency}',
      );

      // Send confirmation SMS
      await _smsService.sendSms(
        phoneNumber: patient.data!.phone,
        message: messageText,
        languageCode: 1, // English by default for payment confirmations
      );
    } catch (e) {
      print('Error sending payment confirmation: $e');
    }
  }
}
