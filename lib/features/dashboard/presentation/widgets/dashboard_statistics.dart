import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../appointment/presentation/providers/appointment_notifier.dart';
import '../../../doctor/presentation/provider/doctor_notifier.dart';
import '../../../patient/presentation/providers/patient_notifier.dart';


class DashboardStatistics extends ConsumerWidget {
  const DashboardStatistics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentNotifierProvider);
    final doctorState = ref.watch(doctorNotifierProvider);
    final patientState = ref.watch(patientNotifierProvider);

    // Count scheduled appointments
    final totalAppointments = appointmentState.appointments.length;
    
    // Count available doctors
    final totalDoctors = doctorState.doctors.length;
    
    // Count active patients
    final totalPatients = patientState.patients.length;

    // Handle loading and error states with fallback values
    final appointmentsValue = appointmentState.isLoading ? "..." : totalAppointments.toString();
    final doctorsValue = doctorState.isLoading ? "..." : totalDoctors.toString();
    final patientsValue = patientState.isLoading ? "..." : totalPatients.toString();

    return Column(
      spacing: 26.5,
      children: [
        StatCard(
          icon: Icons.calendar_today,
          title: 'Total Appointments',
          value: appointmentsValue,
          backgroundColor: const Color(0xFFF0F8FF), // Light blue
          iconColor: const Color(0xFF0E0E48), // Primary color from app_theme.dart
        ),
        StatCard(
          icon: Icons.medical_services_outlined,
          title: 'Total Doctors',
          value: doctorsValue,
          backgroundColor: const Color(0xFFE6F7E7), // Light green
          iconColor: const Color(0xFF00C853), // Success color from app_theme.dart
        ),
        StatCard(
          icon: Icons.person_outline,
          title: 'Total Patients',
          value: patientsValue,
          backgroundColor: const Color(0xFFFFF8E6), // Light amber
          iconColor: const Color(0xFFFFAB00), // Warning color from app_theme.dart
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color backgroundColor;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}