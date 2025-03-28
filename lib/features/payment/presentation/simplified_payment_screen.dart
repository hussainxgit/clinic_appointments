// lib/features/payment/presentation/screens/simplified_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../patient/domain/entities/patient.dart';
import '../domain/whatsapp_payment_service.dart';

class SimplifiedPaymentScreen extends ConsumerStatefulWidget {
  const SimplifiedPaymentScreen({super.key});

  @override
  ConsumerState<SimplifiedPaymentScreen> createState() =>
      _SimplifiedPaymentScreenState();
}

class _SimplifiedPaymentScreenState
    extends ConsumerState<SimplifiedPaymentScreen> {
  bool _isLoading = false;
  bool _linkSent = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final navigationService = ref.read(navigationServiceProvider);
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final appointmentId = args['appointmentId'] as String;
    final amount = args['amount'] as double;
    final currency = args['currency'] as String? ?? 'KWD';
    final patient = args['patient'] as Patient;
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
          _linkSent
              ? _buildSuccessView(appointmentId, navigationService)
              : _buildInitialView(
                appointmentId,
                amount,
                currency,
                patient,
                appointmentDate,
              ),
    );
  }

  Widget _buildInitialView(
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

          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'A payment link will be sent to: ${patient.phone}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: LoadingButton(
              text: 'Send Payment Link via WhatsApp',
              icon: Icons.send,
              isLoading: _isLoading,
              onPressed:
                  () => _sendPaymentLink(
                    appointmentId,
                    amount,
                    currency,
                    patient,
                  ),
            ),
          ),

          const SizedBox(height: 16),
          _buildSecurityNote(),
        ],
      ),
    );
  }

  Widget _buildSuccessView(String appointmentId, dynamic navigationService) {
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
              final service = ref.read(whatsAppPaymentServiceProvider);
              await service.checkPaymentStatus(appointmentId);
              navigationService.goBack(true);
            },
            child: const Text('Check Payment Status'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPaymentLink(
    String appointmentId,
    double amount,
    String currency,
    Patient patient,
  ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
        description: 'Payment for appointment ID: $appointmentId',
      );

      if (result.isSuccess) {
        setState(() {
          _linkSent = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending payment link: $e';
        _isLoading = false;
      });
    }
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

  String _formatDate(DateTime? date) =>
      date != null ? '${date.day}/${date.month}/${date.year}' : '';
}
