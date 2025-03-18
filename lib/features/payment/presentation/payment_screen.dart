import 'dart:async';
import 'package:clinic_appointments/core/di/core_providers.dart';
import 'package:clinic_appointments/core/ui/widgets/app_card.dart';
import 'package:clinic_appointments/core/ui/widgets/loading_button.dart';
import 'package:clinic_appointments/features/payment/domain/entities/payment_response.dart';
import 'package:clinic_appointments/features/payment/domain/payment_service.dart';
import 'package:clinic_appointments/features/payment/presentation/providers/payment_provider.dart';
import 'package:clinic_appointments/features/payment/presentation/widgets/payment_method_selector.dart';
import 'package:clinic_appointments/features/payment/presentation/widgets/payment_status_widget.dart';
import 'package:clinic_appointments/features/payment/presentation/widgets/tap_to_pay_terminal.dart';
import 'package:clinic_appointments/features/patient/domain/entities/patient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_windows/webview_windows.dart';

import '../../../core/navigation/navigation_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  WebviewController? _webViewController;
  String _paymentRecordId = ''; // Initially InvoiceId
  String? _transactionPaymentId; // Store PaymentId from WebView URL
  Timer? _statusCheckTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    debugPrint('PaymentScreen: initState called');
  }

  @override
  void dispose() {
    debugPrint('PaymentScreen: dispose called');
    _statusCheckTimer?.cancel();
    _webViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);
    final paymentNotifier = ref.read(paymentNotifierProvider.notifier);
    final navigationService = ref.read(navigationServiceProvider);

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appointmentId = args['appointmentId'] as String;
    final amount = args['amount'] as double;
    final currency = args['currency'] as String? ?? 'KWD';
    final patient = args['patient'] as Patient;
    final appointmentDate = args['appointmentDate'] as DateTime?;

    _handlePaymentSuccess(paymentState, navigationService, amount, currency);

    return Scaffold(
      appBar: _buildAppBar(
        context,
        paymentState,
        paymentNotifier,
        navigationService,
      ),
      body: _buildBody(
        paymentState,
        paymentNotifier,
        appointmentId,
        amount,
        currency,
        patient,
        appointmentDate,
      ),
    );
  }

  // Extracted Methods

  AppBar _buildAppBar(
    BuildContext context,
    PaymentState paymentState,
    PaymentNotifier paymentNotifier,
    NavigationService navigationService,
  ) {
    return AppBar(
      title: const Text('Process Payment'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed:
            () => _handleBackButton(
              context,
              paymentState,
              paymentNotifier,
              navigationService,
            ),
      ),
    );
  }

  Widget _buildBody(
    PaymentState paymentState,
    PaymentNotifier paymentNotifier,
    String appointmentId,
    double amount,
    String currency,
    Patient patient,
    DateTime? appointmentDate,
  ) {
    if (paymentState.isLoading && paymentState.currentPayment == null) {
      debugPrint('PaymentScreen: Showing loading indicator');
      return const Center(child: CircularProgressIndicator());
    }
    if (paymentState.error != null && paymentState.currentPayment == null) {
      debugPrint('PaymentScreen: Showing error view - ${paymentState.error}');
      return _buildErrorView(paymentState.error!);
    }
    if (paymentState.currentPayment != null) {
      debugPrint('PaymentScreen: Showing payment processing view');
      return _buildPaymentProcessingView(paymentState);
    }
    debugPrint('PaymentScreen: Showing payment initiation view');
    return _buildPaymentInitiationView(
      paymentNotifier,
      paymentState,
      appointmentId,
      amount,
      currency,
      patient,
      appointmentDate,
    );
  }

  void _handlePaymentSuccess(
    PaymentState paymentState,
    NavigationService navigationService,
    double amount,
    String currency,
  ) {
    if (paymentState.lastPaymentStatus?.isSuccessful == true && !_isCompleted) {
      debugPrint('PaymentScreen: Payment successful detected');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isCompleted = true;
        });
        _statusCheckTimer?.cancel();
        _showSuccessDialog(navigationService, amount, currency);
      });
    }
  }

  void _handleBackButton(
    BuildContext context,
    PaymentState paymentState,
    PaymentNotifier paymentNotifier,
    NavigationService navigationService,
  ) {
    if (paymentState.currentPayment != null && !_isCompleted) {
      debugPrint('PaymentScreen: Showing cancel payment confirmation');
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Cancel Payment'),
              content: const Text(
                'Are you sure you want to cancel this payment? Your transaction will not be completed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Stay'),
                ),
                TextButton(
                  onPressed: () {
                    debugPrint(
                      'PaymentScreen: User confirmed payment cancellation',
                    );
                    Navigator.pop(context);
                    paymentNotifier.clearCurrentPayment();
                    navigationService.goBack(false);
                  },
                  child: const Text(
                    'Leave',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
      );
    } else {
      debugPrint('PaymentScreen: Navigating back without confirmation');
      navigationService.goBack(false);
    }
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Payment Error', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              debugPrint('PaymentScreen: User pressed Go Back from error view');
              ref.read(navigationServiceProvider).goBack(false);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInitiationView(
    PaymentNotifier paymentNotifier,
    PaymentState paymentState,
    String appointmentId,
    double amount,
    String currency,
    Patient patient,
    DateTime? appointmentDate,
  ) {
    return SingleChildScrollView(
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
          Text(
            'Select Payment Method',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          PaymentMethodSelector(
            gateways: paymentState.availableGateways,
            selectedGatewayId: paymentState.selectedGatewayId,
            onSelected: paymentNotifier.selectGateway,
          ),
          const SizedBox(height: 32),
          _buildPayButton(
            paymentNotifier,
            appointmentId,
            amount,
            currency,
            patient,
            appointmentDate,
          ),
          const SizedBox(height: 16),
          _buildSecurityNote(),
        ],
      ),
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

  Widget _buildPayButton(
    PaymentNotifier paymentNotifier,
    String appointmentId,
    double amount,
    String currency,
    Patient patient,
    DateTime? appointmentDate,
  ) {
    return SizedBox(
      width: double.infinity,
      child: LoadingButton(
        text: 'Pay ${amount.toStringAsFixed(3)} $currency',
        icon: Icons.payment,
        isLoading: ref.watch(paymentNotifierProvider).isLoading,
        onPressed: () async {
          debugPrint('PaymentScreen: Pay button pressed - Initiating payment');
          final result = await paymentNotifier.processPayment(
            referenceId: appointmentId,
            amount: amount,
            currency: currency,
            patient: patient,
            description:
                'Payment for appointment on ${_formatDate(appointmentDate)}',
            returnUrl: 'https://your-clinic-app.com/payments/callback',
            callbackUrl: 'https://your-clinic-app.com/payments/webhook',
          );

          if (result.isSuccess) {
            debugPrint(
              'PaymentScreen: Payment initiated successfully - PaymentId: ${result.data.paymentId}',
            );
            setState(() {
              _paymentRecordId = result.data.paymentId;
            });
            _startStatusChecking();
          } else {
            debugPrint(
              'PaymentScreen: Payment initiation failed - ${result.error}',
            );
          }
        },
      ),
    );
  }

  Widget _buildPaymentProcessingView(PaymentState paymentState) {
    final currentPayment = paymentState.currentPayment!;
    switch (currentPayment.type) {
      case PaymentResponseType.redirect:
        debugPrint('PaymentScreen: Building WebView for redirect payment');
        return _buildWebViewPayment(currentPayment.redirectUrl!, paymentState);
      case PaymentResponseType.widget:
        debugPrint('PaymentScreen: Building widget-based payment view');
        return paymentState.selectedGatewayId == 'tap_to_pay'
            ? _buildTapToPayWidget(
              currentPayment.paymentId,
              currentPayment.widgetData!,
              paymentState,
            )
            : _buildWidgetPayment(currentPayment.widgetData!, paymentState);
      case PaymentResponseType.error:
        debugPrint('PaymentScreen: Building error view for payment response');
        return _buildErrorView(
          currentPayment.errorMessage ?? 'Unknown payment error',
        );
    }
  }

  Widget _buildWebViewPayment(String url, PaymentState paymentState) {
    _webViewController ??= _createWebViewController(url);
    return Column(
      children: [
        PaymentStatusWidget(status: paymentState.lastPaymentStatus),
        Expanded(child: Webview(_webViewController!)),
      ],
    );
  }

  WebviewController _createWebViewController(String url) {
    debugPrint('PaymentScreen: Creating WebViewController with URL: $url');
    final controller = WebviewController();

    controller
        .initialize()
        .then((_) {
          debugPrint('PaymentScreen: WebView initialized, loading URL');
          controller.loadUrl(url);

          controller.url.listen((currentUrl) {
            debugPrint('PaymentScreen: WebView URL changed to: $currentUrl');
            final uri = Uri.parse(currentUrl);

            // Check for PaymentId in URL
            if (uri.queryParameters.containsKey('PaymentId')) {
              _transactionPaymentId = uri.queryParameters['PaymentId'];
              debugPrint(
                'PaymentScreen: Extracted PaymentId from URL: $_transactionPaymentId',
              );

              // Stop periodic checking with InvoiceId and check status with PaymentId
              _statusCheckTimer?.cancel();
              _checkPaymentStatus(_transactionPaymentId!);
            }
            // Check for callback URL
            else if (currentUrl.startsWith(
              'https://your-clinic-app.com/payments/callback',
            )) {
              final paymentId =
                  uri.queryParameters['paymentId'] ??
                  _transactionPaymentId ??
                  _paymentRecordId;
              debugPrint(
                'PaymentScreen: Callback detected, checking status for PaymentId: $paymentId',
              );
              _checkPaymentStatus(paymentId);
              controller.stop();
            }
          });
        })
        .catchError((e) {
          debugPrint('PaymentScreen: WebView initialization failed: $e');
        });

    return controller;
  }

  Widget _buildWidgetPayment(
    Map<String, dynamic> widgetData,
    PaymentState paymentState,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Please complete your payment'),
          const SizedBox(height: 24),
          PaymentStatusWidget(status: paymentState.lastPaymentStatus),
        ],
      ),
    );
  }

  Widget _buildTapToPayWidget(
    String paymentId,
    Map<String, dynamic> widgetData,
    PaymentState paymentState,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (paymentState.lastPaymentStatus != null)
              PaymentStatusWidget(status: paymentState.lastPaymentStatus),
            const SizedBox(height: 16),
            TapToPayTerminal(
              paymentData: widgetData,
              onPaymentComplete:
                  (status) => _handleTapToPayComplete(paymentId, status),
            ),
          ],
        ),
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
    return Center(
      child: Column(
        children: [
          const Icon(Icons.lock, size: 16),
          const SizedBox(height: 4),
          Text(
            'Secured with encrypted connection',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Your payment information is secure',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(
    NavigationService navigationService,
    double amount,
    String currency,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Payment Successful'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Your payment of ${amount.toStringAsFixed(3)} $currency has been processed successfully.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  debugPrint('PaymentScreen: User confirmed payment success');
                  Navigator.pop(context);
                  navigationService.goBack(true);
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );
  }

  void _startStatusChecking() {
    debugPrint('PaymentScreen: Starting periodic status checking');
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      debugPrint('PaymentScreen: Periodic status check triggered');
      // Use InvoiceId initially until PaymentId is available
      _checkPaymentStatus(_transactionPaymentId ?? _paymentRecordId);
    });
  }

  Future<void> _checkPaymentStatus(String paymentId) async {
    debugPrint(
      'PaymentScreen: Checking payment status for PaymentId: $paymentId',
    );
    await ref
        .read(paymentNotifierProvider.notifier)
        .checkPaymentStatus(paymentId);
  }

  Future<void> _handleTapToPayComplete(String paymentId, dynamic status) async {
    debugPrint('PaymentScreen: Tap to pay completed with status: $status');
    final paymentNotifier = ref.read(paymentNotifierProvider.notifier);
    final paymentService = ref.read(paymentServiceProvider);
    await paymentService.updatePaymentWithStatus(paymentId, status);
    await paymentNotifier.checkPaymentStatus(paymentId);
  }

  String _formatDate(DateTime? date) =>
      date != null ? '${date.day}/${date.month}/${date.year}' : '';
}
