// lib/features/payment/presentation/widgets/tap_to_pay_terminal.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../domain/entities/payment_status.dart';

/// A widget that simulates a physical payment terminal for Tap-to-Pay payments
class TapToPayTerminal extends ConsumerStatefulWidget {
  final Map<String, dynamic> paymentData;
  final Function(PaymentStatus) onPaymentComplete;
  
  const TapToPayTerminal({
    super.key,
    required this.paymentData,
    required this.onPaymentComplete,
  });

  @override
  ConsumerState<TapToPayTerminal> createState() => _TapToPayTerminalState();
}

class _TapToPayTerminalState extends ConsumerState<TapToPayTerminal> {
  bool _isProcessing = false;
  String _statusMessage = 'Ready to process payment';
  final List<String> _logMessages = [];
  int _processingStep = 0;
  Timer? _processingTimer;
  
  // For demonstration purposes
  final List<String> _processingSteps = [
    'Initializing terminal...',
    'Terminal ready',
    'Please tap, insert, or swipe card',
    'Card detected',
    'Reading card information...',
    'Verifying card...',
    'Processing payment...',
    'Connecting to payment network...',
    'Payment authorized',
    'Completing transaction...',
    'Printing receipt...',
    'Payment successful!',
  ];
  
  @override
  void dispose() {
    _processingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.paymentData['amount'] as double;
    final currency = widget.paymentData['currency'] as String;
    final isTestMode = widget.paymentData['isTestMode'] as bool? ?? true;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Terminal header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Terminal',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (isTestMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'TEST MODE',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Payment amount display
          Text(
            '${amount.toStringAsFixed(3)} $currency',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Text(
              _statusMessage,
              style: const TextStyle(
                color: Colors.green,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Terminal log display
          if (_logMessages.isNotEmpty)
            Container(
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: _logMessages.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logMessages[_logMessages.length - 1 - index],
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTerminalButton(
                label: 'Cancel',
                icon: Icons.cancel,
                color: Colors.red[700]!,
                onPressed: _isProcessing
                    ? () => _cancelPayment()
                    : () => _closeTerminal(),
              ),
              _buildTerminalButton(
                label: _isProcessing ? 'Processing...' : 'Process',
                icon: _isProcessing ? Icons.sync : Icons.payment,
                color: Colors.green[700]!,
                onPressed: _isProcessing ? null : () => _processPayment(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTerminalButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  void _processPayment() {
    setState(() {
      _isProcessing = true;
      _processingStep = 0;
      _statusMessage = _processingSteps[0];
      _logMessages.add('> ${_processingSteps[0]}');
    });
    
    // Simulate the payment processing steps
    _processingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          _processingStep++;
          
          if (_processingStep < _processingSteps.length) {
            _statusMessage = _processingSteps[_processingStep];
            _logMessages.add('> ${_processingSteps[_processingStep]}');
          } else {
            // Payment complete
            _completePayment();
            timer.cancel();
          }
        });
      },
    );
  }
  
  void _cancelPayment() {
    _processingTimer?.cancel();
    
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Payment cancelled';
      _logMessages.add('> Payment cancelled by user');
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment cancelled'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _closeTerminal() {
    ref.read(navigationServiceProvider).goBack(false);
  }
  
  void _completePayment() {
    setState(() {
      _isProcessing = false;
    });
    
    // Generate a successful payment status
    final status = PaymentStatus(
      status: PaymentStatusType.successful,
      paymentId: 'tp_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: 'tr_${DateTime.now().millisecondsSinceEpoch}',
      amount: widget.paymentData['amount'] as double,
      currency: widget.paymentData['currency'] as String,
      timestamp: DateTime.now(),
    );
    
    // Notify parent about the completed payment
    widget.onPaymentComplete(status);
  }
}