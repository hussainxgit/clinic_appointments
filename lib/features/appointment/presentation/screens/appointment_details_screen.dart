// lib/features/appointment/presentation/screens/appointment_details_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';

import '../../../doctor/domain/entities/doctor.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointment_notifier.dart';

class AppointmentDetailsScreen extends ConsumerStatefulWidget {
  const AppointmentDetailsScreen({super.key});

  @override
  ConsumerState<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState
    extends ConsumerState<AppointmentDetailsScreen> {
  bool _isCompleting = false;
  bool _isCancelling = false;
  StreamSubscription? _eventSubscription;

  @override
  void initState() {
    super.initState();
    // Subscribe to relevant events
    final eventBus = ref.read(eventBusProvider);
    _eventSubscription = eventBus.on<AppointmentUpdatedEvent>().listen((event) {
      // Handle event
      if (mounted) {
        // Update UI or state
        setState(() {
          // Update relevant state
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final appointment = args['appointment'] as Appointment;
    final patient = args['patient'] as Patient?;
    final doctor = args['doctor'] as Doctor?;

    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          if (appointment.status == 'scheduled')
            // Add this button for appointments with "unpaid" status
            if (appointment.paymentStatus == 'unpaid')
              ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Process Payment'),
                onPressed: () {
                  // Navigate to payment screen with appointment data
                  ref
                      .read(navigationServiceProvider)
                      .navigateTo(
                        '/appointment/payment',
                        arguments: {
                          'appointment': appointment,
                          'patient': patient,
                          'doctor': doctor,
                        },
                      );
                },
              ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              navigationService.navigateTo(
                '/appointment/edit',
                arguments: args,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusBanner(appointment),
              const SizedBox(height: 16),
              _buildAppointmentDetails(appointment),
              const SizedBox(height: 24),
              if (patient != null) _buildPatientCard(patient),
              const SizedBox(height: 16),
              if (doctor != null) _buildDoctorCard(doctor),
              const SizedBox(height: 24),
              if (appointment.status == 'scheduled') ...[
                Row(
                  children: [
                    Expanded(
                      child: LoadingButton(
                        text: 'Complete Appointment',
                        isLoading: _isCompleting,
                        icon: Icons.check_circle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _completeAppointment(appointment.id),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LoadingButton(
                        text: 'Cancel Appointment',
                        isLoading: _isCancelling,
                        icon: Icons.cancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _cancelAppointment(appointment.id),
                      ),
                    ),
                  ],
                ),
              ],
              if (appointment.notes != null &&
                  appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                AppCard(child: Text(appointment.notes!)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(Appointment appointment) {
    Color bannerColor;
    IconData statusIcon;
    String statusText;

    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        bannerColor = Colors.blue;
        statusIcon = Icons.schedule;
        statusText = 'Scheduled';
        break;
      case AppointmentStatus.completed:
        bannerColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        bannerColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Payment: ${appointment.paymentStatus == 'paid' ? 'Paid' : 'Unpaid'}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          if (appointment.status == 'scheduled') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getTimeUntilAppointment(appointment.dateTime),
                style: TextStyle(
                  color: bannerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentDetails(Appointment appointment) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appointment Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: dateFormat.format(appointment.dateTime),
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: timeFormat.format(appointment.dateTime),
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.confirmation_number,
            label: 'Appointment ID',
            value: appointment.id,
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.payment,
            label: 'Payment Status',
            value: appointment.paymentStatus == 'paid' ? 'Paid' : 'Unpaid',
            valueColor:
                appointment.paymentStatus == 'paid'
                    ? Colors.green
                    : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.person,
            label: 'Name',
            value: patient.name,
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.phone,
            label: 'Phone',
            value: patient.phone,
          ),
          if (patient.email != null) ...[
            const Divider(),
            _buildDetailRow(
              icon: Icons.email,
              label: 'Email',
              value: patient.email!,
            ),
          ],
          if (patient.dateOfBirth != null) ...[
            const Divider(),
            _buildDetailRow(
              icon: Icons.cake,
              label: 'Age',
              value: '${_calculateAge(patient.dateOfBirth!)} years',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.person,
            label: 'Name',
            value: doctor.name,
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.medical_services,
            label: 'Specialty',
            value: doctor.specialty,
          ),
          const Divider(),
          _buildDetailRow(
            icon: Icons.phone,
            label: 'Phone',
            value: doctor.phoneNumber,
          ),
          if (doctor.email != null) ...[
            const Divider(),
            _buildDetailRow(
              icon: Icons.email,
              label: 'Email',
              value: doctor.email!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(value, style: TextStyle(fontSize: 16, color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeUntilAppointment(DateTime appointmentDate) {
    final now = DateTime.now();
    final difference = appointmentDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    }

    if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    }

    return '${difference.inMinutes} minutes left';
  }

  int _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _completeAppointment(String appointmentId) async {
    setState(() {
      _isCompleting = true;
    });

    try {
      final result = await ref
          .read(appointmentNotifierProvider.notifier)
          .completeAppointment(
            appointmentId,
            paymentStatus:
                PaymentStatus.paid, // Default to paid when completing
          );

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the appointments list
        ref.read(navigationServiceProvider).goBack();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: const Text(
              'Are you sure you want to cancel this appointment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, cancel'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final result = await ref
          .read(appointmentNotifierProvider.notifier)
          .cancelAppointment(appointmentId);

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the appointments list
        ref.read(navigationServiceProvider).goBack();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Cancel subscription when screen is disposed
    _eventSubscription?.cancel();
    super.dispose();
  }
}
