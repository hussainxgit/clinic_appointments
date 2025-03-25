// lib/features/payment/presentation/providers/payment_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../data/models/payment_record.dart';
import '../../domain/interfaces/payment_gateway.dart';
import '../../domain/payment_service.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_response.dart';
import '../../domain/entities/payment_status.dart';

part 'payment_provider.g.dart';

class PaymentState {
  final List<PaymentRecord> payments;
  final bool isLoading;
  final String? error;
  final PaymentResponse? currentPayment;
  final List<PaymentGateway> availableGateways;
  final String selectedGatewayId;
  final PaymentStatus? lastPaymentStatus;

  PaymentState({
    required this.payments,
    this.isLoading = false,
    this.error,
    this.currentPayment,
    required this.availableGateways,
    required this.selectedGatewayId,
    this.lastPaymentStatus,
  });

  PaymentState copyWith({
    List<PaymentRecord>? payments,
    bool? isLoading,
    String? error,
    PaymentResponse? currentPayment,
    List<PaymentGateway>? availableGateways,
    String? selectedGatewayId,
    PaymentStatus? lastPaymentStatus,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPayment: currentPayment,
      availableGateways: availableGateways ?? this.availableGateways,
      selectedGatewayId: selectedGatewayId ?? this.selectedGatewayId,
      lastPaymentStatus: lastPaymentStatus ?? this.lastPaymentStatus,
    );
  }
}

@riverpod
class PaymentNotifier extends _$PaymentNotifier {
  @override
  PaymentState build() {
    final paymentService = ref.read(paymentServiceProvider);
    final gateways = paymentService.getAvailableGateways();
    final defaultGateway = paymentService.getDefaultGateway();
    
    // Return an initial state without loading
    state = PaymentState(
      payments: [],
      availableGateways: gateways,
      selectedGatewayId: defaultGateway.gatewayId,
    );
    
    return state;
  }

  Future<void> loadPaymentHistory(String patientId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final result = await paymentService.getPaymentHistory(patientId);
      
      if (result.isSuccess) {
        state = state.copyWith(
          payments: result.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result.error,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void selectGateway(String gatewayId) {
    state = state.copyWith(selectedGatewayId: gatewayId);
  }

  Future<Result<PaymentResponse>> processPayment({
    required String referenceId,
    required double amount,
    required String currency,
    required Patient patient,
    String? description,

  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      
      final request = PaymentRequest(
        referenceId: referenceId,
        amount: amount,
        currency: currency,
        customerEmail: patient.email ?? 'customer@example.com',
        customerName: patient.name,
        customerPhone: patient.phone,
        description: description ?? 'Payment for $referenceId',
        metadata: {
          'patientId': patient.id,
          'source': 'clinic_app',
        },
      );
      
      final result = await paymentService.processPayment(
        gatewayId: state.selectedGatewayId,
        request: request,
        patientId: patient.id,
      );
      
      if (result.isSuccess) {
        state = state.copyWith(
          currentPayment: result.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result.error,
          isLoading: false,
        );
      }
      
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return Result.failure(e.toString());
    }
  }

  Future<Result<PaymentStatus>> checkPaymentStatus(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final result = await paymentService.checkPaymentStatus(paymentId);
      
      if (result.isSuccess) {
        state = state.copyWith(
          lastPaymentStatus: result.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result.error,
          isLoading: false,
        );
      }
      
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> processRefund(String paymentId, {double? amount}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final paymentService = ref.read(paymentServiceProvider);
      final result = await paymentService.processRefund(paymentId, amount: amount);
      
      if (result.isSuccess) {
        // Reload payment history after successful refund
        final patientId = state.payments
            .firstWhere((p) => p.id == paymentId, orElse: () => state.payments.first)
            .patientId;
            
        await loadPaymentHistory(patientId);
      } else {
        state = state.copyWith(
          error: result.error,
          isLoading: false,
        );
      }
      
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return Result.failure(e.toString());
    }
  }

  void clearCurrentPayment() {
    state = state.copyWith(
      currentPayment: null,
      lastPaymentStatus: null,
    );
  }
}