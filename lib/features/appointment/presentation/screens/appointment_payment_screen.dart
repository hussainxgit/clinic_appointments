// lib/features/appointment/presentation/screens/appointment_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../../doctor/domain/entities/doctor.dart';
import '../../domain/entities/appointment.dart';

/// This is a bridge screen that prepares payment data and navigates
/// to the payment module to process the payment.
class AppointmentPaymentScreen extends ConsumerWidget {
  const AppointmentPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);

    // Get appointment data from arguments
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appointment = args['appointment'] as Appointment;
    final patient = args['patient'] as Patient?;
    final doctor = args['doctor'] as Doctor?;

    // Default payment amount - in a real app, this would come from the backend
    // or be calculated based on the doctor's fee, services, etc.
    const double paymentAmount = 25.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Process Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appointment details
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow('Date', _formatDateTime(appointment.dateTime)),
                  _buildInfoRow('Patient', patient?.name ?? 'Unknown'),
                  _buildInfoRow('Doctor', doctor?.name ?? 'Unknown'),
                  _buildInfoRow(
                    'Status',
                    _formatStatus(appointment.status.toString()),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment summary
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Consultation Fee',
                    '${paymentAmount.toStringAsFixed(3)} KWD',
                  ),
                  _buildInfoRow(
                    'Payment Status',
                    _formatPaymentStatus(appointment.paymentStatus.toString()),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Total: ${paymentAmount.toStringAsFixed(3)} KWD',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    appointment.paymentStatus == PaymentStatus.paid
                        ? null
                        : () => _navigateToPayment(
                          context,
                          navigationService,
                          appointment,
                          patient!,
                          paymentAmount,
                        ),
                icon: const Icon(Icons.payment),
                label: Text(
                  appointment.paymentStatus == PaymentStatus.paid
                      ? 'Already Paid'
                      : 'Process Payment',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (appointment.paymentStatus == PaymentStatus.paid)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to payment details/history
                    navigationService.navigateTo(
                      '/payment/history',
                      arguments: {'patientId': patient?.id},
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View Receipt'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.capitalize();
    }
  }

  String _formatPaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'unpaid':
        return 'Unpaid';
      default:
        return status.capitalize();
    }
  }

  void _navigateToPayment(
    BuildContext context,
    dynamic navigationService,
    Appointment appointment,
    Patient patient,
    double amount,
  ) async {
    // Navigate to payment screen with required data
    final result = await navigationService.navigateTo(
      '/payment/send',
      arguments: {
        'appointmentId': appointment.id,
        'amount': amount,
        'currency': 'KWD',
        'patient': patient,
        'appointmentDate': appointment.dateTime,
        'doctorId': appointment.doctorId,
      },
    );

    // Handle payment result
    if (result == true) {
      // Payment was successful
      // In a real app, you would update the appointment payment status via a service call
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment processed successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to appointment details
      navigationService.goBack(true);
    }
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
