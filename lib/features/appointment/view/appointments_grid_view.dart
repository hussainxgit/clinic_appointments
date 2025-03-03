import 'package:clinic_appointments/features/appointment/view/appointment_card.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../doctor/models/doctor.dart';
import '../../patient/models/patient.dart';
import '../models/appointment.dart';

class AppointmentsGridView extends StatelessWidget {
  final DateTime selectedDay;
  const AppointmentsGridView({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Consumer<ClinicService>(builder: (context, clinicService, child) {
      final combinedAppointments =
          clinicService.getCombinedAppointmentsByDate(selectedDay);

      if (combinedAppointments.isEmpty) {
        return _buildEmptyState(theme, colorScheme);
      }
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateCrossAxisCount(context),
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        padding: const EdgeInsets.only(bottom: 80), // Space for FAB
        itemCount: combinedAppointments.length,
        itemBuilder: (context, index) {
          final appointment =
              combinedAppointments[index]['appointment'] as Appointment;
          final patient = combinedAppointments[index]['patient'] as Patient;
          final doctor = combinedAppointments[index]['doctor'] as Doctor;
          return AppointmentCard(
            appointment: appointment,
            patient: patient,
            doctor: doctor,
            index: index,
          );
        },
      );
    });
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width > 1200) {
      return 4;
    } else if (width > 900) {
      return 3;
    } else if (width > 600) {
      return 2;
    } else {
      return 1;
    }
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found for the selected date.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select another date or create a new appointment',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
