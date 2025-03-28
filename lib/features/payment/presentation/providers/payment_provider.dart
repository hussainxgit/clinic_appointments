// lib/features/payment/presentation/providers/payment_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../data/models/payment_record.dart';
import '../../data/payment_repository_provider.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/whatsapp_payment_service.dart';

part 'payment_provider.g.dart';

class PaymentState {
  final List<PaymentRecord> payments;
  final bool isLoading;
  final String? error;
  final PaymentStatus? lastPaymentStatus;
  final bool linkSent;

  PaymentState({
    required this.payments,
    this.isLoading = false,
    this.error,
    this.lastPaymentStatus,
    this.linkSent = false,
  });

  PaymentState copyWith({
    List<PaymentRecord>? payments,
    bool? isLoading,
    String? error,
    PaymentStatus? lastPaymentStatus,
    bool? linkSent,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastPaymentStatus: lastPaymentStatus ?? this.lastPaymentStatus,
      linkSent: linkSent ?? this.linkSent,
    );
  }
}

@riverpod
class PaymentNotifier extends _$PaymentNotifier {
  @override
  PaymentState build() {
    return PaymentState(payments: []);
  }

  Future<void> loadPaymentHistory(String patientId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final paymentRepository = ref.read(paymentRepositoryProvider);
      final payments = await paymentRepository.getPaymentsByPatient(patientId);

      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<Result<PaymentRecord>> sendPaymentLink({
    required String appointmentId,
    required double amount,
    required String currency,
    required Patient patient,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final paymentService = ref.read(whatsAppPaymentServiceProvider);
      
      final result = await paymentService.sendPaymentLink(
        referenceId: appointmentId,
        amount: amount,
        currency: currency,
        patientId: patient.id,
        patientName: patient.name,
        patientPhone: patient.phone,
        patientEmail: patient.email ?? 'patient@example.com',
        description: description ?? 'Payment for appointment ID: $appointmentId',
      );
      
      if (result.isSuccess) {
        state = state.copyWith(
          linkSent: true,
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
      final paymentService = ref.read(whatsAppPaymentServiceProvider);
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

  void resetPaymentState() {
    state = state.copyWith(
      linkSent: false,
      lastPaymentStatus: null,
      error: null,
    );
  }
}