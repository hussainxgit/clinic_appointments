import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../data/repositories/payment_repository_impl.dart';
import '../data/services/myfatoorah_service.dart';
import 'repositories/payment_repository.dart';
import 'services/payment_service.dart';
import '../../../features/messaging/services/sms_service.dart';
import '../../../features/appointment/data/appointment_providers.dart';
import '../../../features/patient/data/patient_providers.dart';

// Repository provider
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return PaymentRepositoryImpl(firestore: firestore);
});

// MyFatoorah service provider
final myFatoorahServiceProvider = Provider<MyFatoorahService>((ref) {
  return MyFatoorahService();
});

// Payment service provider
final paymentServiceProvider = Provider<PaymentService>((ref) {
  final paymentRepository = ref.watch(paymentRepositoryProvider);
  final myFatoorahService = ref.watch(myFatoorahServiceProvider);
  final smsService = ref.watch(smsServiceProvider);
  final appointmentRepository = ref.watch(appointmentRepositoryProvider);
  final patientRepository = ref.watch(patientRepositoryProvider);

  return PaymentService(
    paymentRepository: paymentRepository,
    myFatoorahService: myFatoorahService,
    smsService: smsService,
    appointmentRepository: appointmentRepository,
    patientRepository: patientRepository,
  );
});

// Payment history state provider
final paymentHistoryProvider =
    StateNotifierProvider<PaymentHistoryNotifier, PaymentHistoryState>((ref) {
      final paymentRepository = ref.watch(paymentRepositoryProvider);
      return PaymentHistoryNotifier(paymentRepository);
    });

// Payment history state
class PaymentHistoryState {
  final List<dynamic> payments;
  final bool isLoading;
  final String? error;

  PaymentHistoryState({
    required this.payments,
    this.isLoading = false,
    this.error,
  });

  PaymentHistoryState copyWith({
    List<dynamic>? payments,
    bool? isLoading,
    String? error,
  }) {
    return PaymentHistoryState(
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Payment history notifier
class PaymentHistoryNotifier extends StateNotifier<PaymentHistoryState> {
  final PaymentRepository _repository;

  PaymentHistoryNotifier(this._repository)
    : super(PaymentHistoryState(payments: []));

  Future<void> loadAllPayments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final payments = await _repository.getAllPayments();
      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadPatientPayments(String patientId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final payments = await _repository.getPaymentsByPatient(patientId);
      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadAppointmentPayments(String appointmentId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final payments = await _repository.getPaymentsByAppointment(
        appointmentId,
      );
      state = state.copyWith(payments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
