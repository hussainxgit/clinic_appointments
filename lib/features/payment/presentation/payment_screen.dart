// lib/features/payment/presentation/screens/payment_screen.dart
import 'dart:async';
import 'package:clinic_appointments/features/payment/presentation/providers/payment_provider.dart';
import 'package:clinic_appointments/features/payment/presentation/widgets/payment_status_widget.dart';
import 'package:clinic_appointments/features/payment/presentation/widgets/tap_to_pay_terminal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';

import '../../patient/domain/entities/patient.dart';
import '../domain/interfaces/payment_gateway.dart';
import '../domain/payment_service.dart';

import 'widgets/payment_method_selector.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late WebViewController? _webViewController;
  String _paymentRecordId = '';
  Timer? _statusCheckTimer;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _webViewController = null;
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);
    final paymentNotifier = ref.read(paymentNotifierProvider.notifier);
    final navigationService = ref.read(navigationServiceProvider);

    // Get arguments from the route
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appointmentId = args['appointmentId'] as String;
    final amount = args['amount'] as double;
    final currency = args['currency'] as String? ?? 'KWD';
    final patient = args['patient'] as Patient;
    final appointmentDate = args['appointmentDate'] as DateTime?;

    // Handle payment completed status
    if (paymentState.lastPaymentStatus?.isSuccessful == true && !_isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isCompleted = true;
        });

        // Stop status checking
        _statusCheckTimer?.cancel();

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Payment Successful'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your payment of ${amount.toStringAsFixed(3)} $currency has been processed successfully.',
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Return to the calling screen with success status
                      navigationService.goBack(true);
                    },
                    child: const Text('Continue'),
                  ),
                ],
              ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Confirm before leaving
            if (paymentState.currentPayment != null && !_isCompleted) {
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
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Stay'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
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
              navigationService.goBack(false);
            }
          },
        ),
      ),
      body:
          paymentState.isLoading && paymentState.currentPayment == null
              ? const Center(child: CircularProgressIndicator())
              : paymentState.error != null &&
                  paymentState.currentPayment == null
              ? _buildErrorView(paymentState.error!)
              : paymentState.currentPayment != null
              ? _buildPaymentProcessingView(paymentState)
              : _buildPaymentInitiationView(
                appointmentId,
                amount,
                currency,
                patient,
                appointmentDate,
              ),
    );
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
              ref.read(navigationServiceProvider).goBack(false);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInitiationView(
    String appointmentId,
    double amount,
    String currency,
    Patient patient,
    DateTime? appointmentDate,
  ) {
    final paymentNotifier = ref.read(paymentNotifierProvider.notifier);
    final paymentState = ref.watch(paymentNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Details Card
          AppCard(
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
                  _buildInfoRow(
                    'Appointment Date',
                    '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}',
                  ),
                _buildInfoRow('Patient', patient.name),
                _buildInfoRow(
                  'Amount',
                  '${amount.toStringAsFixed(3)} $currency',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment Method Selection
          Text(
            'Select Payment Method',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          PaymentMethodSelector(
            gateways: paymentState.availableGateways,
            selectedGatewayId: paymentState.selectedGatewayId,
            onSelected: (gatewayId) {
              paymentNotifier.selectGateway(gatewayId);
            },
          ),

          const SizedBox(height: 32),

          // Pay Button
          SizedBox(
            width: double.infinity,
            child: LoadingButton(
              text: 'Pay ${amount.toStringAsFixed(3)} $currency',
              icon: Icons.payment,
              isLoading: paymentState.isLoading,
              onPressed: () async {
                final result = await paymentNotifier.processPayment(
                  referenceId: appointmentId,
                  amount: amount,
                  currency: currency,
                  patient: patient,
                  description:
                      'Payment for appointment on ${appointmentDate?.day}/${appointmentDate?.month}/${appointmentDate?.year}',
                  returnUrl: 'https://your-clinic-app.com/payments/callback',
                  callbackUrl: 'https://your-clinic-app.com/payments/webhook',
                );

                if (result.isSuccess) {
                  // Store payment record ID for status checking
                  _paymentRecordId = result.data.paymentId;

                  // Start periodic status checking
                  _statusCheckTimer = Timer.periodic(
                    const Duration(seconds: 5),
                    (_) => _checkPaymentStatus(_paymentRecordId),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Security Note
          Center(
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
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProcessingView(PaymentState paymentState) {
    final currentPayment = paymentState.currentPayment!;

    // Handle different response types
    if (currentPayment.type == PaymentResponseType.redirect) {
      return _buildWebViewPayment(currentPayment.redirectUrl!, paymentState);
    } else if (currentPayment.type == PaymentResponseType.widget) {
      // Check if this is a tap-to-pay widget
      if (paymentState.selectedGatewayId == 'tap_to_pay') {
        return _buildTapToPayWidget(
          currentPayment.paymentId,
          currentPayment.widgetData!,
          paymentState,
        );
      } else {
        return _buildWidgetPayment(currentPayment.widgetData!, paymentState);
      }
    } else {
      // Handle error case
      return _buildErrorView(
        currentPayment.errorMessage ?? 'Unknown payment error',
      );
    }
  }

  // Updated _buildWebViewPayment method in payment_screen.dart
  Widget _buildWebViewPayment(String url, PaymentState paymentState) {
    return Column(
      children: [
        PaymentStatusWidget(status: paymentState.lastPaymentStatus),
        Expanded(
          child: WebViewWidget(controller: _createWebViewController(url)),
        ),
      ],
    );
  }

  WebViewController _createWebViewController(String url) {
    final controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(url))
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                // Check if the navigation is to our callback URL
                if (request.url.startsWith(
                  'https://your-clinic-app.com/payments/callback',
                )) {
                  // Parse URL for parameters
                  final uri = Uri.parse(request.url);
                  final paymentId = uri.queryParameters['paymentId'];

                  if (paymentId != null) {
                    _checkPaymentStatus(paymentId);
                  }

                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          );

    _webViewController = controller;
    return controller;
  }

  Widget _buildWidgetPayment(
    Map<String, dynamic> widgetData,
    PaymentState paymentState,
  ) {
    // This would be implementation-specific based on the payment gateway
    // For example, rendering a credit card form or other payment widget
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Please complete your payment'),
          const SizedBox(height: 24),
          PaymentStatusWidget(status: paymentState.lastPaymentStatus),
          // Here you would render the payment widget components
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
              onPaymentComplete: (status) async {
                // Update the payment record with the status
                final paymentNotifier = ref.read(
                  paymentNotifierProvider.notifier,
                );
                final paymentService = ref.read(paymentServiceProvider);

                await paymentService.updatePaymentWithStatus(
                  _paymentRecordId,
                  status,
                );

                // Refresh the payment status
                await paymentNotifier.checkPaymentStatus(_paymentRecordId);
              },
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

  Future<void> _checkPaymentStatus(String paymentId) async {
    await ref
        .read(paymentNotifierProvider.notifier)
        .checkPaymentStatus(paymentId);
  }
}
