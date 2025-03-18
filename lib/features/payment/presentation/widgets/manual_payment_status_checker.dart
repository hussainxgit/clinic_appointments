import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/payment_status.dart';
import '../providers/payment_provider.dart';

class ManualPaymentStatusChecker extends ConsumerStatefulWidget {
  final String paymentId;
  final VoidCallback onSuccess;

  const ManualPaymentStatusChecker({
    super.key,
    required this.paymentId,
    required this.onSuccess,
  });

  @override
  ConsumerState<ManualPaymentStatusChecker> createState() =>
      _ManualPaymentStatusCheckerState();
}

class _ManualPaymentStatusCheckerState
    extends ConsumerState<ManualPaymentStatusChecker> {
  bool _isChecking = false;
  int _attempts = 0;
  String? _lastError;
  bool _showRecoveryOptions = false;
  final TextEditingController _manualIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manualIdController.text = widget.paymentId;
  }

  @override
  void dispose() {
    _manualIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'External Payment Window',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Complete your payment in the external browser window.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(_isChecking ? 'Checking...' : 'Check Payment Status'),
            onPressed: _isChecking ? null : _checkStatus,
          ),
          if (_lastError != null) ...[
            const SizedBox(height: 16),
            Text(
              'Error: $_lastError',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          if (_showRecoveryOptions) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Payment Recovery Options',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _manualIdController,
              decoration: const InputDecoration(
                labelText: 'Payment ID (from receipt or email)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _checkManualId,
              child: const Text('Check Payment ID'),
            ),
            TextButton(
              onPressed: () {
                // Navigate back to payment selection
                Navigator.of(context).pop();
              },
              child: const Text('Try Different Payment Method'),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Payment ID: ${widget.paymentId}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
      _lastError = null;
    });

    try {
      final result = await ref
          .read(paymentNotifierProvider.notifier)
          .checkPaymentStatus(widget.paymentId);

      setState(() {
        _isChecking = false;
        _attempts++;
      });

      if (result.isSuccess) {
        final status = result.data;
        if (status.status == PaymentStatusType.successful) {
          widget.onSuccess();
        } else if (status.status == PaymentStatusType.failed) {
          setState(() {
            _lastError = 'Payment failed. Please try again.';
            _showRecoveryOptions = true;
          });
        } else if (_attempts >= 3 &&
            status.status == PaymentStatusType.pending) {
          setState(() {
            _lastError =
                'Payment still pending. If you completed the payment, try checking again.';
            _showRecoveryOptions = true;
          });
        }
      } else {
        setState(() {
          _lastError = result.error;
          _showRecoveryOptions = _attempts >= 2;
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _lastError = e.toString();
        _showRecoveryOptions = _attempts >= 2;
      });
    }
  }

  Future<void> _checkManualId() async {
    final manualId = _manualIdController.text.trim();
    if (manualId.isEmpty) {
      setState(() {
        _lastError = 'Please enter a payment ID';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _lastError = null;
    });

    try {
      final result = await ref
          .read(paymentNotifierProvider.notifier)
          .checkPaymentStatus(manualId);

      setState(() {
        _isChecking = false;
      });

      if (result.isSuccess &&
          result.data.status == PaymentStatusType.successful) {
        widget.onSuccess();
      } else {
        setState(() {
          _lastError =
              result.isFailure
                  ? result.error
                  : 'Payment status: ${result.data.status}';
        });
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _lastError = e.toString();
      });
    }
  }
}
