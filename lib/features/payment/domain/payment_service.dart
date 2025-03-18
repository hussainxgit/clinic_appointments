// lib/features/payment/domain/payment_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/result.dart';
import '../data/payment_repository_provider.dart';
import '../data/models/payment_record.dart';
import '../data/repository/payment_repository.dart';
import '../data/gateways/myfatoorah_gateway.dart';
import '../data/gateways/tap_to_pay_gateway.dart';
import 'interfaces/payment_gateway.dart';
import 'entities/payment_request.dart';
import 'entities/payment_response.dart';
import 'entities/payment_status.dart';

// Payment configuration provider
final paymentConfigProvider = Provider<Map<String, dynamic>>((ref) {
  // In production, these could come from a secure backend or Flutter Dotenv
  return {
    'defaultGateway': 'myfatoorah', // or 'tap'
    'gateways': {
      'myfatoorah': {
        'apiKey':
            'blWGxi69g3K_GfnvzzUF2Fr6xtsj39bnF3my22-OOW-Kn3G5z8jzhw2xKVkigyV-A2GU5MHK98vL2VoavcyMNICKg3TK0HXR0SifQM_8w_j2kFc5pvcEfmkpWPBmukQ40z2HAsQMNmPl8r8hEzShT6VtQzKBpwZhZrxgwalPcex55SD6u0V_lMIG4odeYuoVHrjaD3sH7x0_CqT8Rv2of-hKvc3W4d_KUQQZXpzNEB1e5f7Y4kf7mytMvttotUcZOY6A-_HgkWIRD4NSOODjjIdXrb_8ZyQ_fWbT3THyjf72SYIan7h45sA99Xddh6tZBs1MtSeexjDeLfFPkoE6oIYQbXnPewCt5FpVbDt6u6DHQ5w9Xkn2o30qEKvoxHnJxAsP4kIDG1jDp1TYQECPvBww4WGLLcVshGVWCsgwNzmp3oSXc7XOIWhhUJ6Szo7RE2kg_2Nwt1CU6QBu2XIDD8Rg8TqF4SaUYgVBLtUhtapYuBrMjnmPXBCm6Yptq55mUDMpH59op5NfbLc5ULW8-WeSPMbw_sAJNJuGqYAOtp2YlDnsIf2plW2F_1U4XzVGmRr8eaU6Zllxv-_qSPKQag9O1of848evV6a8KQyQPpBYMJ3wyh2_VNzarSlP8DiLTFoUmXozQuPIhjVM3ow92KCVqP0ifG47PJY4AEqyJ6bbzAzv',
        'testMode': false,
      },
      'tap': {
        'apiKey': 'YOUR_TAP_API_KEY',
        'secretKey': 'YOUR_TAP_SECRET_KEY',
        'testMode': true,
      },
      'tap_to_pay': {'testMode': true},
    },
  };
});

class PaymentService {
  final PaymentRepository _repository;
  final Map<String, PaymentGateway> _gateways = {};
  final String _defaultGatewayId;

  PaymentService({
    required PaymentRepository repository,
    required Map<String, dynamic> config,
  }) : _repository = repository,
       _defaultGatewayId = config['defaultGateway'] ?? 'myfatoorah' {
    // Initialize all supported gateways
    final myfatoorah = MyFatoorahGateway();
    final tapToPay = TapToPayGateway();

    _gateways[myfatoorah.gatewayId] = myfatoorah;
    _gateways[tapToPay.gatewayId] = tapToPay;

    // Initialize gateways with their configs
    final gatewayConfigs = config['gateways'] as Map<String, dynamic>? ?? {};

    for (var gateway in _gateways.values) {
      final gatewayConfig =
          gatewayConfigs[gateway.gatewayId] as Map<String, dynamic>? ?? {};
      gateway.initialize(gatewayConfig);
    }
  }

  /// Get available payment gateways
  List<PaymentGateway> getAvailableGateways() {
    return _gateways.values.toList();
  }

  /// Get a specific payment gateway by ID
  PaymentGateway? getGateway(String gatewayId) {
    return _gateways[gatewayId];
  }

  /// Get the default payment gateway
  PaymentGateway getDefaultGateway() {
    return _gateways[_defaultGatewayId]!;
  }

  /// Process a refund for a payment
  Future<Result<bool>> processRefund(String recordId, {double? amount}) async {
    try {
      final record = await _repository.getPaymentById(recordId);
      if (record == null) {
        return Result.failure('Payment record not found');
      }

      if (record.status != 'successful') {
        return Result.failure('Only successful payments can be refunded');
      }

      final gateway = _gateways[record.gatewayId];
      if (gateway == null) {
        return Result.failure('Payment gateway not found');
      }

      final success = await gateway.processRefund(
        record.gatewayPaymentId,
        amount: amount,
      );

      if (success) {
        // Update the record
        final updatedRecord = record.copyWith(
          status:
              amount != null && amount < record.amount
                  ? 'partially_refunded'
                  : 'refunded',
          updatedAt: DateTime.now(),
        );

        await _repository.updatePaymentRecord(updatedRecord);
        return Result.success(true);
      } else {
        return Result.failure('Refund processing failed');
      }
    } catch (e) {
      return Result.failure('Refund error: ${e.toString()}');
    }
  }

  /// Handle webhook callbacks from payment gateways
  Future<Result<PaymentStatus>> handleWebhookCallback(
    String gatewayId,
    Map<String, dynamic> callbackData,
  ) async {
    try {
      final gateway = _gateways[gatewayId];
      if (gateway == null) {
        return Result.failure('Payment gateway not found');
      }

      if (!gateway.validateCallback(callbackData)) {
        return Result.failure('Invalid callback data');
      }

      final status = gateway.extractStatusFromCallback(callbackData);

      // Find and update the payment record
      final records = await _repository.getPaymentsByReference(
        status.paymentId,
      );
      for (var record in records) {
        if (record.gatewayId == gatewayId) {
          await _updateRecordFromStatus(record, status);
          break;
        }
      }

      return Result.success(status);
    } catch (e) {
      return Result.failure('Webhook processing error: ${e.toString()}');
    }
  }

  /// Update payment status directly (used for manual/tap-to-pay methods)
  Future<Result<PaymentRecord>> updatePaymentWithStatus(
    String recordId,
    PaymentStatus status,
  ) async {
    try {
      final record = await _repository.getPaymentById(recordId);
      if (record == null) {
        return Result.failure('Payment record not found');
      }

      final updatedRecord = await _updateRecordFromStatus(record, status);
      return Result.success(updatedRecord);
    } catch (e) {
      return Result.failure('Failed to update payment: ${e.toString()}');
    }
  }

  /// Get payment history for a patient
  Future<Result<List<PaymentRecord>>> getPaymentHistory(
    String patientId,
  ) async {
    try {
      final records = await _repository.getPaymentsByPatient(patientId);
      return Result.success(records);
    } catch (e) {
      return Result.failure(
        'Failed to retrieve payment history: ${e.toString()}',
      );
    }
  }

  /// Process a payment using the specified gateway with better error handling
  Future<Result<PaymentResponse>> processPayment({
    required String gatewayId,
    required PaymentRequest request,
    required String patientId,
  }) async {
    try {
      final gateway = _gateways[gatewayId];
      if (gateway == null) {
        return Result.failure('Payment gateway not found');
      }

      // Create payment record in pending state
      final paymentRecord = PaymentRecord(
        id: '',
        referenceId: request.referenceId,
        gatewayId: gatewayId,
        gatewayPaymentId: '',
        patientId: patientId,
        amount: request.amount,
        currency: request.currency,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final savedRecord = await _repository.createPaymentRecord(paymentRecord);
      print(
        'Created payment record: ${savedRecord.id} for referenceId: ${request.referenceId}',
      );

      // Process payment with the gateway
      final response = await gateway.createPayment(request);

      if (response.isSuccess) {
        // Update record with gateway payment ID
        final updatedRecord = savedRecord.copyWith(
          gatewayPaymentId: response.paymentId,
          updatedAt: DateTime.now(),
        );

        await _repository.updatePaymentRecord(updatedRecord);
        print('Updated payment record with gateway ID: ${response.paymentId}');
        return Result.success(response);
      } else {
        // Update record with error
        final updatedRecord = savedRecord.copyWith(
          status: 'failed',
          errorMessage: response.errorMessage,
          updatedAt: DateTime.now(),
        );

        await _repository.updatePaymentRecord(updatedRecord);
        return Result.failure(
          response.errorMessage ?? 'Payment processing failed',
        );
      }
    } catch (e) {
      print('Error in processPayment: $e');
      return Result.failure('Payment processing error: ${e.toString()}');
    }
  }

  /// Check the status of a payment with more thorough lookup and recovery
  Future<Result<PaymentStatus>> checkPaymentStatus(String paymentId) async {
    try {
      print('Checking status for payment ID: $paymentId');

      // Try to find the record
      final record = await _repository.getPaymentById(paymentId);

      if (record == null) {
        print('Payment record not found for ID: $paymentId');

        // Try all gateways since we don't know which one processed this payment
        for (final entry in _gateways.entries) {
          try {
            final gateway = entry.value;
            print('Trying gateway: ${gateway.gatewayId}');

            final status = await gateway.checkPaymentStatus(paymentId);
            if (status.status != PaymentStatusType.unknown) {
              print(
                'Found status with gateway ${gateway.gatewayId}: ${status.status}',
              );

              // Create a recovery record
              try {
                final newRecord = PaymentRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  referenceId:
                      'recovered_${DateTime.now().millisecondsSinceEpoch}',
                  gatewayId: gateway.gatewayId,
                  gatewayPaymentId: paymentId,
                  patientId: 'recovered', // This would be unknown in recovery
                  amount: status.amount ?? 0.0,
                  currency: status.currency ?? 'KWD',
                  status: _mapStatusTypeToString(status.status),
                  transactionId: status.transactionId,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  metadata: status.gatewayResponse,
                );

                await _repository.createPaymentRecord(newRecord);
                print('Created recovery record: ${newRecord.id}');
              } catch (e) {
                print('Error creating recovery record: $e');
              }

              return Result.success(status);
            }
          } catch (e) {
            print('Error checking with gateway ${entry.key}: $e');
          }
        }

        return Result.failure(
          'Payment record not found and no gateway returned valid status',
        );
      }

      // Normal flow when record is found
      print('Found payment record: ${record.id}, gateway: ${record.gatewayId}');
      final gateway = _gateways[record.gatewayId];
      if (gateway == null) {
        return Result.failure('Payment gateway ${record.gatewayId} not found');
      }

      // Use the gateway payment ID if available, otherwise use the provided ID
      final idToCheck =
          record.gatewayPaymentId.isNotEmpty
              ? record.gatewayPaymentId
              : paymentId;

      print('Checking status with gateway using ID: $idToCheck');
      final status = await gateway.checkPaymentStatus(idToCheck);

      // Update the record with the latest status
      await _updateRecordFromStatus(record, status);

      return Result.success(status);
    } catch (e) {
      print('Detailed error in checkPaymentStatus: $e');
      return Result.failure('Failed to check payment status: ${e.toString()}');
    }
  }

  /// Update a payment record based on a payment status with improved error handling
  Future<PaymentRecord> _updateRecordFromStatus(
    PaymentRecord record,
    PaymentStatus status,
  ) async {
    try {
      String paymentStatus = _mapStatusTypeToString(status.status);

      final updatedRecord = record.copyWith(
        status: paymentStatus,
        transactionId: status.transactionId ?? record.transactionId,
        updatedAt: DateTime.now(),
        metadata: status.gatewayResponse ?? record.metadata,
        errorMessage: status.errorMessage ?? record.errorMessage,
      );

      print('Updating record ${record.id} with status: $paymentStatus');
      await _repository.updatePaymentRecord(updatedRecord);
      return updatedRecord;
    } catch (e) {
      print('Error updating record from status: $e');
      // Return original record if update fails
      return record;
    }
  }

  // Helper method to map status type to string
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

// Provider for the PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  final config = ref.watch(paymentConfigProvider);
  return PaymentService(repository: repository, config: config);
});
