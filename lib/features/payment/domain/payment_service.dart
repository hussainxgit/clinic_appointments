// lib/features/payment/domain/payment_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/result.dart';
import '../data/payment_repository_provider.dart';
import '../data/models/payment_record.dart';
import '../data/repository/payment_repository.dart';
import '../data/gateways/myfatoorah_gateway.dart';
import '../data/gateways/tap_gateway.dart';
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
        'apiKey': 'rLtt6JWvbUHDDhsZnfpAhpYk4dxYDQkbcPTyGaKp2TYqQgG7FGZ5Th_WD53Oq8Ebz6A53njUoo1w3pjU1D4vs_ZMqFiz_j0urb_BH9Oq9VZoKFoJEDAbRZepGcQanImyYrry7Kt6MnMdgfG5jn4HngWoRdKduNNyP4kzcp3mRv7x00ahkm9LAK7ZRieg7k1PDAnBIOG3EyVSJ5kK4WLMvYr7sCwHbHcu4A5WwelxYK0GMJy37bNAarSJDFQsJ2ZvJjvMDmfWwDVFEVe_5tOomfVNt6bOg9mexbGjMrnHBnKnZR1vQbBtQieDlQepzTZMuQrSuKn-t5XZM7V6fCW7oP-uXGX-sMOajeX65JOf6XVpk29DP6ro8WTAflCDANC193yof8-f5_EYY-3hXhJj7RBXmizDpneEQDSaSz5sFk0sV5qPcARJ9zGG73vuGFyenjPPmtDtXtpx35A-BVcOSBYVIWe9kndG3nclfefjKEuZ3m4jL9Gg1h2JBvmXSMYiZtp9MR5I6pvbvylU_PP5xJFSjVTIz7IQSjcVGO41npnwIxRXNRxFOdIUHn0tjQ-7LwvEcTXyPsHXcMD8WtgBh-wxR8aKX7WPSsT1O8d8reb2aR7K3rkV3K82K_0OgawImEpwSvp9MNKynEAJQS6ZHe_J_l77652xwPNxMRTMASk1ZsJL',
        'testMode': true,
      },
      'tap': {
        'apiKey': 'YOUR_TAP_API_KEY',
        'secretKey': 'YOUR_TAP_SECRET_KEY',
        'testMode': true,
      },
      'tap_to_pay': {
        'testMode': true,
      },
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
    final tap = TapGateway();
    final tapToPay = TapToPayGateway();
    
    _gateways[myfatoorah.gatewayId] = myfatoorah;
    _gateways[tap.gatewayId] = tap;
    _gateways[tapToPay.gatewayId] = tapToPay;
    
    // Initialize gateways with their configs
    final gatewayConfigs = config['gateways'] as Map<String, dynamic>? ?? {};
    
    for (var gateway in _gateways.values) {
      final gatewayConfig = gatewayConfigs[gateway.gatewayId] as Map<String, dynamic>? ?? {};
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
  
  /// Process a payment using the specified gateway
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
      
      // Process payment with the gateway
      final response = await gateway.createPayment(request);
      
      if (response.isSuccess) {
        // Update record with gateway payment ID
        final updatedRecord = savedRecord.copyWith(
          gatewayPaymentId: response.paymentId,
          updatedAt: DateTime.now(),
        );
        
        await _repository.updatePaymentRecord(updatedRecord);
        return Result.success(response);
      } else {
        // Update record with error
        final updatedRecord = savedRecord.copyWith(
          status: 'failed',
          errorMessage: response.errorMessage,
          updatedAt: DateTime.now(),
        );
        
        await _repository.updatePaymentRecord(updatedRecord);
        return Result.failure(response.errorMessage ?? 'Payment processing failed');
      }
    } catch (e) {
      return Result.failure('Payment processing error: ${e.toString()}');
    }
  }
  
  /// Check the status of a payment
  Future<Result<PaymentStatus>> checkPaymentStatus(String recordId) async {
    try {
      final record = await _repository.getPaymentById(recordId);
      if (record == null) {
        return Result.failure('Payment record not found');
      }
      
      final gateway = _gateways[record.gatewayId];
      if (gateway == null) {
        return Result.failure('Payment gateway not found');
      }
      
      final status = await gateway.checkPaymentStatus(record.gatewayPaymentId);
      
      // Update the record with the latest status
      await _updateRecordFromStatus(record, status);
      
      return Result.success(status);
    } catch (e) {
      return Result.failure('Failed to check payment status: ${e.toString()}');
    }
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
      
      final success = await gateway.processRefund(record.gatewayPaymentId, amount: amount);
      
      if (success) {
        // Update the record
        final updatedRecord = record.copyWith(
          status: amount != null && amount < record.amount ? 'partially_refunded' : 'refunded',
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
      final records = await _repository.getPaymentsByReference(status.paymentId);
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
    PaymentStatus status
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
  Future<Result<List<PaymentRecord>>> getPaymentHistory(String patientId) async {
    try {
      final records = await _repository.getPaymentsByPatient(patientId);
      return Result.success(records);
    } catch (e) {
      return Result.failure('Failed to retrieve payment history: ${e.toString()}');
    }
  }
  
  /// Update a payment record based on a payment status
  Future<PaymentRecord> _updateRecordFromStatus(PaymentRecord record, PaymentStatus status) async {
    String paymentStatus;
    switch (status.status) {
      case PaymentStatusType.successful:
        paymentStatus = 'successful';
        break;
      case PaymentStatusType.pending:
        paymentStatus = 'pending';
        break;
      case PaymentStatusType.processing:
        paymentStatus = 'processing';
        break;
      case PaymentStatusType.failed:
        paymentStatus = 'failed';
        break;
      case PaymentStatusType.refunded:
        paymentStatus = 'refunded';
        break;
      case PaymentStatusType.partiallyRefunded:
        paymentStatus = 'partially_refunded';
        break;
      default:
        paymentStatus = 'unknown';
    }
    
    final updatedRecord = record.copyWith(
      status: paymentStatus,
      transactionId: status.transactionId ?? record.transactionId,
      updatedAt: DateTime.now(),
      metadata: status.gatewayResponse ?? record.metadata,
      errorMessage: status.errorMessage ?? record.errorMessage,
    );
    
    await _repository.updatePaymentRecord(updatedRecord);
    return updatedRecord;
  }
}

// Provider for the PaymentService
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final repository = ref.watch(paymentRepositoryProvider);
  final config = ref.watch(paymentConfigProvider);
  return PaymentService(repository: repository, config: config);
});