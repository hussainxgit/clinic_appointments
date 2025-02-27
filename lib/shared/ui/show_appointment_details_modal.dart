import 'package:flutter/material.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';

import '../../features/appointment/models/appointment.dart';
import '../../features/patient/models/patient.dart';

void showAppointmentDetailsModal(
    BuildContext context, Map<String, dynamic> appointmentData) {
  final appointment = appointmentData['appointment'] as Appointment;
  final patient = appointmentData['patient'] as Patient;

  showDialog(
    context: context,
    builder: (context) {
      return SizedBox(
        width: 500,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 16),

                  // Patient Information
                  _buildSectionHeader(context, 'Patient Information'),
                  _buildUserInfo(context, patient),
                  const SizedBox(height: 16),

                  // Appointment Information
                  _buildSectionHeader(context, 'Appointment Information'),
                  _buildAppointmentInfo(context, appointment),
                  const SizedBox(height: 16),

                  // Actions
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildHeader(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        'Appointment Details',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
      IconButton(
        icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

Widget _buildSectionHeader(BuildContext context, String title) {
  return Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
  );
}

Widget _buildUserInfo(context, Patient patient) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(Icons.person_outline,
        color: Theme.of(context).colorScheme.secondary),
    title: Text(patient.name,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
    subtitle: Text(patient.phone,
        style:
            TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
  );
}

Widget _buildAppointmentInfo(context, Appointment appointment) {
  return Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.calendar_today,
            color: Theme.of(context).colorScheme.secondary),
        title: Text('Date & Time',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(appointment.dateTime.dateOnly(),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.medical_services,
            color: Theme.of(context).colorScheme.secondary),
        title: Text('Status',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        subtitle: Text(
          appointment.status.toUpperCase(),
          style: TextStyle(
            color: _getStatusColor(appointment.status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'scheduled':
      return Colors.green;
    case 'cancelled':
      return Colors.red;
    default:
      return Colors.orange;
  }
}

Widget _buildActionButtons(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Expanded(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Reschedule',
              style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text('Confirm',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ),
    ],
  );
}
