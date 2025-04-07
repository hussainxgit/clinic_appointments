import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/payment_record.dart';
import '../../domain/providers.dart';
import '../../domain/services/payment_service.dart';

final paymentProcessingProvider = StateNotifierProvider.autoDispose<
  PaymentProcessingNotifier,
  PaymentProcessingState
>((ref) {
  final paymentService = ref.watch(paymentServiceProvider);
  return PaymentProcessingNotifier(paymentService);
});

class PaymentProcessingState {
  final bool isCreatingPayment;
  final bool isGeneratingLink;
  final bool isSendingLink;
  final bool isCompleted;
  final String? error;
  final PaymentRecord? payment;

  PaymentProcessingState({
    this.isCreatingPayment = false,
    this.isGeneratingLink = false,
    this.isSendingLink = false,
    this.isCompleted = false,
    this.error,
    this.payment,
  });

  PaymentProcessingState copyWith({
    bool? isCreatingPayment,
    bool? isGeneratingLink,
    bool? isSendingLink,
    bool? isCompleted,
    String? error,
    PaymentRecord? payment,
  }) {
    return PaymentProcessingState(
      isCreatingPayment: isCreatingPayment ?? this.isCreatingPayment,
      isGeneratingLink: isGeneratingLink ?? this.isGeneratingLink,
      isSendingLink: isSendingLink ?? this.isSendingLink,
      isCompleted: isCompleted ?? this.isCompleted,
      error: error,
      payment: payment ?? this.payment,
    );
  }

  bool get isLoading => isCreatingPayment || isGeneratingLink || isSendingLink;
}

class PaymentProcessingNotifier extends StateNotifier<PaymentProcessingState> {
  final PaymentService _paymentService;

  PaymentProcessingNotifier(this._paymentService)
    : super(PaymentProcessingState());

  Future<void> processPayment({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required double amount,
    String currency = 'KWD',
  }) async {
    // Reset state first
    state = state.copyWith(
      isCreatingPayment: false,
      isGeneratingLink: false,
      isSendingLink: false,
      isCompleted: false,
      error: null,
      payment: null,
    );

    try {
      // Step 1: Create payment record
      state = state.copyWith(isCreatingPayment: true);

      final paymentResult = await _paymentService.createPaymentForAppointment(
        appointmentId: appointmentId,
        patientId: patientId,
        doctorId: doctorId,
        amount: amount,
        currency: currency,
      );

      if (paymentResult.isFailure) {
        state = state.copyWith(
          isCreatingPayment: false,
          error: paymentResult.error,
        );
        return;
      }

      final payment = paymentResult.data;
      state = state.copyWith(isCreatingPayment: false, payment: payment);

      // Step 2: Generate payment link if not already generated
      if (payment.paymentLink == null) {
        state = state.copyWith(isGeneratingLink: true);

        final linkResult = await _paymentService.generatePaymentLink(
          payment.id,
        );

        if (linkResult.isFailure) {
          state = state.copyWith(
            isGeneratingLink: false,
            error: linkResult.error,
          );
          return;
        }

        state = state.copyWith(
          isGeneratingLink: false,
          payment: linkResult.data,
        );
      }

      // Step 3: Send Message
      state = state.copyWith(isSendingLink: true);

      final sendResult = await _paymentService.sendPaymentLinkViaWhatsApp(
        payment.id,
      );

      if (sendResult.isFailure) {
        state = state.copyWith(isSendingLink: false, error: sendResult.error);
        return;
      }

      state = state.copyWith(isSendingLink: false, isCompleted: true);
    } catch (e) {
      state = state.copyWith(
        isCreatingPayment: false,
        isGeneratingLink: false,
        isSendingLink: false,
        error: e.toString(),
      );
    }
  }

  Future<void> checkPaymentStatus() async {
    if (state.payment == null) return;

    state = state.copyWith(isGeneratingLink: true, error: null);

    final statusResult = await _paymentService.checkPaymentStatus(
      state.payment!.id,
    );

    state = state.copyWith(isGeneratingLink: false);

    if (statusResult.isFailure) {
      state = state.copyWith(error: statusResult.error);
    }
  }
}
