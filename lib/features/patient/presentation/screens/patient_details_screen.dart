// lib/features/patient/presentation/screens/patient_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../appointment/domain/entities/appointment.dart';
import '../../domain/entities/patient.dart';
import '../../../appointment/presentation/providers/appointment_notifier.dart';

class PatientDetailsScreen extends ConsumerWidget {
  const PatientDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ModalRoute.of(context)!.settings.arguments as Patient;
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.sms),
            onPressed: () {
              _sendWhatsAppTemplateMessage(patient, ref);
            },
            tooltip: 'Send WhatsApp Message',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              navigationService.navigateTo('/patient/edit', arguments: patient);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPatientInfoCard(context, patient),
            const SizedBox(height: 16),
            _buildContactInfo(patient),
            const SizedBox(height: 16),
            _buildAppointmentsSection(context, ref, patient),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          navigationService.navigateTo(
            '/appointment/create',
            arguments: {'patientId': patient.id},
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Appointment'),
      ),
    );
  }

  Widget _buildPatientInfoCard(BuildContext context, Patient patient) {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildInfoRow(
                      icon: Icons.wc,
                      label:
                          patient.gender == PatientGender.male
                              ? 'Male'
                              : 'Female',
                    ),
                    if (patient.dateOfBirth != null) ...[
                      _buildInfoRow(
                        icon: Icons.cake,
                        label: 'Age: ${_calculateAge(patient.dateOfBirth!)}',
                      ),
                    ],
                    _buildInfoRow(
                      icon: Icons.event,
                      label:
                          'Registered: ${DateFormat('MMM d, yyyy').format(patient.registeredAt)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color:
                  patient.status == PatientStatus.active
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                patient.status == PatientStatus.active ? 'Active' : 'Inactive',
                style: TextStyle(
                  color:
                      patient.status == PatientStatus.active
                          ? Colors.green
                          : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Patient patient) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(icon: Icons.phone, label: patient.phone),
          if (patient.email != null && patient.email!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(icon: Icons.email, label: patient.email!),
          ],
          if (patient.address != null && patient.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(icon: Icons.home, label: patient.address!),
          ],
          if (patient.notes != null && patient.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(patient.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection(
    BuildContext context,
    WidgetRef ref,
    Patient patient,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('View All'),
              onPressed: () {
                ref
                    .read(navigationServiceProvider)
                    .navigateTo(
                      '/appointment/list',
                      arguments: {'patientId': patient.id},
                    );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildAppointmentsList(ref, patient),
      ],
    );
  }

  Widget _buildAppointmentsList(WidgetRef ref, Patient patient) {
    final appointmentState = ref.watch(appointmentNotifierProvider);

    if (appointmentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointmentState.error != null) {
      return Center(child: Text('Error: ${appointmentState.error}'));
    }

    // Filter appointments for this patient
    final appointments =
        appointmentState.appointments
            .where((item) => (item['appointment'].patientId == patient.id))
            .toList();

    if (appointments.isEmpty) {
      return AppCard(
        child: SizedBox(
          height: 120,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  'No appointments found',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref
                        .read(navigationServiceProvider)
                        .navigateTo(
                          '/appointment/create',
                          arguments: {'patientId': patient.id},
                        );
                  },
                  child: const Text('Schedule Appointment'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Sort appointments by date, most recent first
    appointments.sort((a, b) {
      final dateA = a['appointment'].dateTime as DateTime;
      final dateB = b['appointment'].dateTime as DateTime;
      return dateB.compareTo(dateA);
    });

    // Take only the most recent 3 appointments
    final recentAppointments = appointments.take(3).toList();

    return Column(
      children:
          recentAppointments.map((item) {
            final appointment = item['appointment'];
            final doctor = item['doctor'];

            return AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              onTap: () {
                ref
                    .read(navigationServiceProvider)
                    .navigateTo('/appointment/details', arguments: item);
              },
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 70,
                    color: _getAppointmentStatusColor(appointment.status),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat(
                            'EEE, MMM d, yyyy • h:mm a',
                          ).format(appointment.dateTime),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (doctor != null) ...[
                          const SizedBox(height: 4),
                          Text('Dr. ${doctor.name}'),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getAppointmentStatusColor(
                                  appointment.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _capitalizeFirst(appointment.status.toString()),
                                style: TextStyle(
                                  color: _getAppointmentStatusColor(
                                    appointment.status,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
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

  Color _getAppointmentStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  void _sendWhatsAppTemplateMessage(Patient patient, WidgetRef ref) {
    if (patient.phone.isEmpty) return;

    // Navigate to the template message screen with patient phone pre-filled
    ref
        .read(navigationServiceProvider)
        .navigateTo('/messaging/template', arguments: patient.phone);
  }
}
