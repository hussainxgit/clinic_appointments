// lib/features/payment/services/whatsapp_payment_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../.my_secrets.dart';
import '../../../core/utils/result.dart';
import '../data/models/payment_record.dart';
import '../data/payment_repository_provider.dart';
import '../data/repository/payment_repository.dart';
import '../../messaging/services/sms_service.dart';
import '../../messaging/domain/entities/sms_message.dart';
import '../domain/entities/payment_request.dart';
import '../domain/entities/payment_status.dart';
import '../data/gateways/myfatoorah_gateway.dart';

part 'whatsapp_payment_service.g.dart';

@riverpod
WhatsAppPaymentService whatsAppPaymentService(Ref ref) {
  final paymentRepository = ref.watch(paymentRepositoryProvider);
  final smsService = ref.watch(smsServiceProvider);
  final myFatoorah = MyFatoorahGateway();

  // Initialize MyFatoorah gateway with config
  final config = {
    'apiKey': myfatoorahApiKey, // Replace with your actual key
    'testMode': true, // Set to false for production
  };
  myFatoorah.initialize(config);

  return WhatsAppPaymentService(
    paymentRepository: paymentRepository,
    smsService: smsService,
    paymentGateway: myFatoorah,
  );
}

class WhatsAppPaymentService {
  final PaymentRepository _paymentRepository;
  final SmsService _smsService;
  final MyFatoorahGateway _paymentGateway;

  WhatsAppPaymentService({
    required PaymentRepository paymentRepository,
    required SmsService smsService,
    required MyFatoorahGateway paymentGateway,
  }) : _paymentRepository = paymentRepository,
       _smsService = smsService,
       _paymentGateway = paymentGateway;

  /// Send a payment link via WhatsApp
  Future<Result<PaymentRecord>> sendPaymentLink({
    required String referenceId,
    required double amount,
    required String currency,
    required String patientId,
    required String patientName,
    required String patientPhone,
    required String patientEmail,
    String? description,
  }) async {
    try {
      // 1. Create payment request
      final paymentRequest = PaymentRequest(
        referenceId: referenceId,
        amount: amount,
        currency: currency,
        customerEmail: patientEmail,
        customerName: patientName,
        customerPhone: patientPhone,
        description: description ?? 'Payment for appointment $referenceId',
        // Add any webhook URLs for handling completion
        callbackUrl:
            'https://us-central1-eye-clinic-41214.cloudfunctions.net/myFatoorahWebhook',
      );

      // 2. Initialize payment with MyFatoorah to get payment URL
      final paymentResponse = await _paymentGateway.createPayment(
        paymentRequest,
      );

      if (!paymentResponse.isSuccess) {
        return Result.failure(
          'Failed to create payment: ${paymentResponse.errorMessage}',
        );
      }

      // 3. Create pending payment record in Firebase
      final paymentRecord = PaymentRecord(
        id: '',
        referenceId: referenceId,
        gatewayId: _paymentGateway.gatewayId,
        gatewayPaymentId: paymentResponse.paymentId,
        patientId: patientId,
        amount: amount,
        currency: currency,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final savedPaymentRecord = await _paymentRepository.createPaymentRecord(
        paymentRecord,
      );

      // 4. Send WhatsApp message with payment link
      final whatsappMessage = SmsMessage(
        to: patientPhone,
        from: '', // Will be filled by provider
        body:
            'Thank you for choosing our clinic. Please complete your payment using this link: ${paymentResponse.redirectUrl}',
        metadata: {
          'isWhatsApp': true, // Flag to indicate this is a WhatsApp message
          'paymentId': paymentResponse.paymentId,
          'appointmentId': referenceId,
        },
      );

      // Send via Twilio WhatsApp
      final messageResponse = await _smsService.sendSms(
        whatsappMessage,
        providerId: 'twilio',
      );

      if (!messageResponse.success) {
        print(
          'Warning: WhatsApp message failed to send: ${messageResponse.errorMessage}',
        );
        // We don't fail the whole process if just the message fails
      }

      return Result.success(savedPaymentRecord);
    } catch (e) {
      print('Error sending payment link: $e');
      return Result.failure('Failed to send payment link: $e');
    }
  }

  /// Check payment status
  Future<Result<PaymentStatus>> checkPaymentStatus(String paymentId) async {
    try {
      // Find the payment record
      final record = await _paymentRepository.getPaymentById(paymentId);
      if (record == null) {
        return Result.failure('Payment record not found');
      }

      // Check status with gateway
      final status = await _paymentGateway.checkPaymentStatus(
        record.gatewayPaymentId,
      );

      // Update record if status has changed
      if (_mapStatusTypeToString(status.status) != record.status) {
        final updatedRecord = record.copyWith(
          status: _mapStatusTypeToString(status.status),
          transactionId: status.transactionId ?? record.transactionId,
          updatedAt: DateTime.now(),
          metadata: {...(record.metadata ?? {}), ...?(status.gatewayResponse)},
        );

        await _paymentRepository.updatePaymentRecord(updatedRecord);
      }

      return Result.success(status);
    } catch (e) {
      return Result.failure('Failed to check payment status: $e');
    }
  }

  // Convert PaymentStatusType to string
  String _mapStatusTypeToString(PaymentStatusType statusType) {
    switch (statusType) {
      case PaymentStatusType.successful:
        return 'successful';
      case PaymentStatusType.pending:
        return 'pending';
      case PaymentStatusType.processing:
        return 'processing';
      case PaymentStatusType.failed:
        return 'failed';
      case PaymentStatusType.refunded:
        return 'refunded';
      case PaymentStatusType.partiallyRefunded:
        return 'partially_refunded';
      default:
        return 'unknown';
    }
  }
}
