import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../../../core/di/core_providers.dart';
import '../../domain/providers.dart';
import '../../data/models/payment_record.dart';
import '../../domain/services/payment_service.dart';
import '../../../patient/domain/entities/patient.dart';
import 'package:intl/intl.dart';

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
    // Step 1: Create payment record
    state = state.copyWith(isCreatingPayment: true, error: null);

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

      final linkResult = await _paymentService.generatePaymentLink(payment.id);

      if (linkResult.isFailure) {
        state = state.copyWith(
          isGeneratingLink: false,
          error: linkResult.error,
        );
        return;
      }

      state = state.copyWith(isGeneratingLink: false, payment: linkResult.data);
    }

    // Step 3: Send WhatsApp message
    state = state.copyWith(isSendingLink: true);

    final sendResult = await _paymentService.sendPaymentLinkViaWhatsApp(
      payment.id,
    );

    if (sendResult.isFailure) {
      state = state.copyWith(isSendingLink: false, error: sendResult.error);
      return;
    }

    state = state.copyWith(isSendingLink: false, isCompleted: true);
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

class PaymentLinkScreen extends ConsumerStatefulWidget {
  const PaymentLinkScreen({super.key});

  @override
  ConsumerState<PaymentLinkScreen> createState() => _PaymentLinkScreenState();
}

class _PaymentLinkScreenState extends ConsumerState<PaymentLinkScreen> {
  late final Map<String, dynamic> args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = ref.read(navigationServiceProvider);
    final processingState = ref.watch(paymentProcessingProvider);

    final appointmentId = args['appointmentId'] as String;
    final amount = args['amount'] as double;
    final currency = args['currency'] as String? ?? 'KWD';
    final patient = args['patient'] as Patient;
    final doctorId = args['doctorId'] as String;
    final appointmentDate = args['appointmentDate'] as DateTime?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigationService.goBack(false),
        ),
      ),
      body:
          processingState.isCompleted
              ? _buildSuccessView(navigationService)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaymentDetailsCard(
                      appointmentId,
                      amount,
                      currency,
                      patient,
                      appointmentDate,
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ListTile(
                            leading: Icon(Icons.message, color: Colors.green),
                            title: Text('WhatsApp Payment Link'),
                            subtitle: Text(
                              'We will send a payment link to the patient\'s WhatsApp',
                            ),
                            trailing: Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'A payment link will be sent to: ${patient.phone}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (processingState.error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                processingState.error!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    _buildProcessIndicator(processingState),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        text: 'Send Payment Link via WhatsApp',
                        icon: Icons.send,
                        isLoading: processingState.isLoading,
                        onPressed:
                            () => _processPayment(
                              appointmentId: appointmentId,
                              patientId: patient.id,
                              doctorId: doctorId,
                              amount: amount,
                              currency: currency,
                            ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildSecurityNote(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProcessIndicator(PaymentProcessingState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProcessStep(
          title: 'Create Payment Record',
          isCompleted: state.payment != null,
          isInProgress: state.isCreatingPayment,
        ),
        _buildProcessStep(
          title: 'Generate Payment Link',
          isCompleted: state.payment?.paymentLink != null,
          isInProgress: state.isGeneratingLink,
        ),
        _buildProcessStep(
          title: 'Send WhatsApp Message',
          isCompleted: state.isCompleted,
          isInProgress: state.isSendingLink,
        ),
      ],
    );
  }

  Widget _buildProcessStep({
    required String title,
    required bool isCompleted,
    required bool isInProgress,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (isCompleted)
            Icon(Icons.check_circle, color: Colors.green.shade600)
          else if (isInProgress)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).primaryColor,
              ),
            )
          else
            Icon(Icons.circle_outlined, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isInProgress ? FontWeight.bold : FontWeight.normal,
              color:
                  isInProgress
                      ? Theme.of(context).primaryColor
                      : isCompleted
                      ? Colors.black
                      : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(dynamic navigationService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Payment Link Sent!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'A WhatsApp message with payment link has been sent to the patient\'s phone number.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The appointment status will be updated automatically once payment is completed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => navigationService.goBack(true),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Back to Appointment'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () async {
              // Check payment status once before returning
              await ref
                  .read(paymentProcessingProvider.notifier)
                  .checkPaymentStatus();
              navigationService.goBack(true);
            },
            child: const Text('Check Payment Status'),
          ),
        ],
      ),
    );
  }

  void _processPayment({
    required String appointmentId,
    required String patientId,
    required String doctorId,
    required double amount,
    required String currency,
  }) {
    ref
        .read(paymentProcessingProvider.notifier)
        .processPayment(
          appointmentId: appointmentId,
          patientId: patientId,
          doctorId: doctorId,
          amount: amount,
          currency: currency,
        );
  }

  Widget _buildPaymentDetailsCard(
    String appointmentId,
    double amount,
    String currency,
    Patient patient,
    DateTime? appointmentDate,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          _buildInfoRow('Appointment ID', appointmentId),
          if (appointmentDate != null)
            _buildInfoRow('Appointment Date', _formatDate(appointmentDate)),
          _buildInfoRow('Patient', patient.name),
          _buildInfoRow('Amount', '${amount.toStringAsFixed(3)} $currency'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return const Center(
      child: Column(
        children: [
          Icon(Icons.lock, size: 16),
          SizedBox(height: 4),
          Text(
            'Payment will be processed securely via WhatsApp',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEE, MMM d, yyyy - h:mm a').format(date);
  }
}
