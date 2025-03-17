// lib/features/payment/domain/payment_service.dart
import 'dart:async';
import 'package:clinic_appointments/features/payment/data/payment_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/result.dart';
import '../data/repository/payment_repository.dart';
import '../data/models/payment_record.dart';
import '../domain/interfaces/payment_gateway.dart';

import '../data/gateways/myfatoorah_gateway.dart';
import '../data/gateways/tap_gateway.dart';
import '../data/gateways/tap_to_pay_gateway.dart';

// Payment configuration provider
final paymentConfigProvider = Provider<Map<String, dynamic>>((ref) {
  // In production, these could come from a secure backend or Flutter Dotenv
  return {
    'defaultGateway': 'myfatoorah', // or 'tap'
    'gateways': {
      'myfatoorah': {
        'apiKey': 'j4lc68ycMg3Vk30apbsbLnGWMtWbLXzRGilTN4l8ZTz6qlZ5SI7SYZbrRdjtI5FuRWz3lg6jnCV15VBU9cFhA_pRo4qiQCyZtTdjaAkN2QOq-TOWRuj81B6dVbP4DR-nhs4c_KVsYqfHmHcqb3hVS9Aymc771P_e13LU4X_Zd3bKyVY_L9WWBQ3bQtK-gAHpn9RVoVioQo1g_ZaaAiV4GP8scxfEMy02uN-OvcRGXExThTanoqwKwXgzU9dxJQteD0vbgVfeVbtzoWIjnroB2oPQuE_PZtG1ljdq0r5jFJp3fREVJEa2K8DjkMIo0KHavlPBClW11HyBYsnmGxVjXGFMeXVFRrXosl9KudRR8s98QusPDcbP1e4oDv3iJo8bYMDAT8F327FGBjGdonzNsaOIvfzCMdI-jpxaZ7wh5eO-KTTNX4N5xP6Vp0CShkhPTT16z84JFQvnzaJ6nRtYJ6w9AJbi3WghON9x350OIaR0ffThTrincoBGo_0szIj-TcyZhNAT4RRRd01gEm3O6d-qeDVL6xhVKYh9g8Op1AWBB5q5oWlPD8VSRHsWzR7Z05RdPK8qKOXaoA9iQBpo9HS_qddqF9KCyOvy9fhOtYOxdLYv5NpbefMAGfLl87NzjBxCUfKR5KPnGg3Jibv6xSk500KIo_xoKQvcsAo5PvEGvUcQ',
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