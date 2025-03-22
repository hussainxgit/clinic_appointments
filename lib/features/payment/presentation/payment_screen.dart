import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/di/core_providers.dart';
import '../../../core/ui/widgets/app_card.dart';
import '../../../core/ui/widgets/loading_button.dart';
import '../../patient/domain/entities/patient.dart';
import '../domain/entities/payment_response.dart';
import '../domain/entities/payment_status.dart';
import '../presentation/providers/payment_provider.dart';
import '../presentation/widgets/payment_method_selector.dart';
import '../presentation/widgets/payment_status_widget.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _paymentRecordId = '';
  Timer? _statusCheckTimer;
  bool _isCompleted = false;
  int _statusCheckAttempts = 0;
  final int _maxStatusCheckAttempts = 30;
  
  // Status tracking
  PaymentStatusType _currentStatus = PaymentStatusType.pending;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('PaymentScreen: initState called');
  }

  @override
  void dispose() {
    debugPrint('PaymentScreen: dispose called');
    _statusCheckTimer?.cancel();
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
      appBar: AppBar(
        title: const Text('Process Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackButton(
            context,
            paymentState,
            paymentNotifier,
            navigationService,
          ),
        ),
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
      
      // Update status based on latest payment status
      if (paymentState.lastPaymentStatus != null) {
        _currentStatus = paymentState.lastPaymentStatus!.status;
        _statusMessage = paymentState.lastPaymentStatus!.errorMessage;
      }
      
      return _buildPaymentProcessingView(
        paymentState, 
        appointmentId,
        amount, 
        currency
      );
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
    dynamic navigationService,
    double amount,
    String currency,
  ) {
    if (paymentState.lastPaymentStatus?.isSuccessful == true && !_isCompleted) {
      debugPrint('PaymentScreen: Payment successful detected');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isCompleted = true;
          _currentStatus = PaymentStatusType.successful;
        });
        _statusCheckTimer?.cancel();
        _showSuccessDialog(navigationService, amount, currency);
      });
    } else if (paymentState.lastPaymentStatus?.status == PaymentStatusType.failed && !_isCompleted) {
      setState(() {
        _currentStatus = PaymentStatusType.failed;
        _statusMessage = paymentState.lastPaymentStatus?.errorMessage ?? 'Payment failed';
      });
    }
  }

  void _handleBackButton(
    BuildContext context,
    PaymentState paymentState,
    PaymentNotifier paymentNotifier,
    dynamic navigationService,
  ) {
    if (paymentState.currentPayment != null && !_isCompleted) {
      debugPrint('PaymentScreen: Showing cancel payment confirmation');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
                debugPrint('PaymentScreen: User confirmed payment cancellation');
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
            description: 'Payment for appointment on ${_formatDate(appointmentDate)}',
            returnUrl: 'https://your-clinic-app.com/payments/callback',
            callbackUrl: 'https://your-clinic-app.com/payments/webhook',
          );

          if (result.isSuccess) {
            debugPrint('PaymentScreen: Payment initiated successfully - PaymentId: ${result.data.paymentId}');
            setState(() {
              _paymentRecordId = result.data.paymentId;
              _statusCheckAttempts = 0;
              _currentStatus = PaymentStatusType.pending;
              
            });
            
            if (result.data.type == PaymentResponseType.redirect) {
              // Launch browser with URL instead of using in-app WebView
              _launchBrowser(result.data.redirectUrl!);
            }
            
            _startStatusChecking();
          } else {
            debugPrint('PaymentScreen: Payment initiation failed - ${result.error}');
          }
        },
      ),
    );
  }

  Future<void> _launchBrowser(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('PaymentScreen: Failed to launch browser: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open browser: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPaymentProcessingView(
    PaymentState paymentState,
    String appointmentId,
    double amount,
    String currency,
  ) {
    final currentPayment = paymentState.currentPayment!;
    
    if (currentPayment.type == PaymentResponseType.redirect) {
      return _buildPaymentStatusScreen(
        paymentState, 
        currentPayment.redirectUrl!,
        appointmentId,
        amount,
        currency
      );
    } 
    else if (currentPayment.type == PaymentResponseType.widget) {
      // Handle widget payments as before
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
    else {
      // Handle errors
      return _buildErrorView(
        currentPayment.errorMessage ?? 'Unknown payment error',
      );
    }
  }

  Widget _buildPaymentStatusScreen(
    PaymentState paymentState,
    String url,
    String appointmentId,
    double amount,
    String currency,
  ) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Title and header
                      const Text(
                        'Payment In Progress',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Status Animation
                      SizedBox(
                        height: 200,
                        child: _buildStatusAnimation(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Status message
                      _buildStatusMessage(),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      _buildActionButtons(url),
                      
                      const SizedBox(height: 16),
                      Text(
                        'Payment ID: $_paymentRecordId',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusAnimation() {
    switch (_currentStatus) {
      case PaymentStatusType.pending:
      case PaymentStatusType.processing:
        // Show loading animation
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // If you have Lottie animations:
            // Lottie.asset('assets/animations/payment_loading.json'),
            // Otherwise use a simple loading indicator:
            const CircularProgressIndicator(
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for payment confirmation...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        );
      
      case PaymentStatusType.successful:
        // Show success animation
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie.asset('assets/animations/payment_success.json'),
            // Or use an icon:
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        );
      
      case PaymentStatusType.failed:
        // Show failure animation
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie.asset('assets/animations/payment_failed.json'),
            // Or use an icon:
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        );
      
      default:
        return const CircularProgressIndicator();
    }
  }
  
  Widget _buildStatusMessage() {
    switch (_currentStatus) {
      case PaymentStatusType.pending:
        return const Text(
          'Your payment is being processed. Please complete payment in the browser window.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        );
      
      case PaymentStatusType.processing:
        return const Text(
          'Your payment is being verified. This may take a moment.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        );
      
      case PaymentStatusType.successful:
        return const Text(
          'Your payment has been successfully processed. Thank you!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.green),
        );
      
      case PaymentStatusType.failed:
        return Text(
          _statusMessage ?? 'Your payment could not be processed. Please try again.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.red),
        );
      
      default:
        return const Text(
          'Checking payment status...',
          textAlign: TextAlign.center,
        );
    }
  }
  
  Widget _buildActionButtons(String url) {
    switch (_currentStatus) {
      case PaymentStatusType.pending:
      case PaymentStatusType.processing:
        return Column(
          children: [
            LoadingButton(
              text: 'Check Payment Status',
              onPressed: _checkManualStatus,
              isLoading: _statusCheckTimer != null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Payment Page Again'),
              onPressed: () => _launchBrowser(url),
            ),
          ],
        );
      
      case PaymentStatusType.successful:
        return ElevatedButton(
          onPressed: () {
            _showSuccessDialog(
              ref.read(navigationServiceProvider),
              double.tryParse(_paymentRecordId) ?? 0.0,
              'KWD',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Continue'),
        );
      
      case PaymentStatusType.failed:
        return Column(
          children: [
            ElevatedButton(
              onPressed: () => _launchBrowser(url),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _statusCheckTimer?.cancel();
                ref.read(paymentNotifierProvider.notifier).clearCurrentPayment();
                // Go back to payment method selection
                setState(() {
                  _currentStatus = PaymentStatusType.unknown;
                  _statusMessage = null;
                });
              },
              child: const Text('Choose Another Payment Method'),
            ),
          ],
        );
      
      default:
        return const SizedBox();
    }
  }
  
  Future<void> _checkManualStatus() async {
    try {
      setState(() {
        _statusCheckAttempts = 0;
      });
      
      // Cancel any existing timer
      _statusCheckTimer?.cancel();
      
      // Start a new checking cycle
      _startStatusChecking();
      
      // Show a snackbar to indicate checking
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking payment status...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('PaymentScreen: Error in manual status check: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    dynamic navigationService,
    double amount,
    String currency,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
    _statusCheckTimer?.cancel(); // Cancel any existing timer
    
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_statusCheckAttempts < _maxStatusCheckAttempts) {
        debugPrint('PaymentScreen: Periodic status check triggered (attempt ${_statusCheckAttempts + 1})');
        _checkPaymentStatus(_paymentRecordId);
        _statusCheckAttempts++;
      } else {
        debugPrint('PaymentScreen: Maximum status check attempts reached');
        _statusCheckTimer?.cancel();
        
        if (!_isCompleted && mounted) {
          setState(() {
            _currentStatus = PaymentStatusType.unknown;
            _statusMessage = 'Status check timed out. Please check manually.';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment status check timed out. Please try checking manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  Future<void> _checkPaymentStatus(String paymentId) async {
    debugPrint('PaymentScreen: Checking payment status for PaymentId: $paymentId');
    
    try {
      await ref
          .read(paymentNotifierProvider.notifier)
          .checkPaymentStatus(paymentId);
    } catch (e) {
      debugPrint('PaymentScreen: Error checking payment status: $e');
    }
  }

  String _formatDate(DateTime? date) =>
      date != null ? '${date.day}/${date.month}/${date.year}' : '';
}