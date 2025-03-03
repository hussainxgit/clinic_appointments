import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../appointment/models/appointment.dart';
import '../../patient/models/patient.dart';
import '../../appointment/view/edit_appointment_dialog.dart';

class RecentAppointmentsListView extends StatelessWidget {
  final List<Map<String, dynamic>> combinedAppointments;

  const RecentAppointmentsListView({
    super.key,
    required this.combinedAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: combinedAppointments.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          itemBuilder: (context, index) {
            final appointment =
                combinedAppointments[index]['appointment'] as Appointment;
            final patient = combinedAppointments[index]['patient'] as Patient;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getAvatarColor(index),
                child: Text(
                  patient.name[0].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              title: Text(
                patient.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      appointment.dateTime.dateOnly(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    _buildPaymentStatusChip(appointment.paymentStatus, context),
                    _buildStatusChip(appointment.status, context),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (appointment.dateTime.removeTime().isSameDayOrAfter(today))
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditAppointmentDialog(
                            appointment: appointment,
                            patientName: patient.name,
                          ),
                        );
                      },
                      icon: Icon(Icons.edit_outlined, size: 24),
                      color: Theme.of(context).colorScheme.primary,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () {
                        Provider.of<ClinicService>(context, listen: false)
                            .removeAppointment(
                                appointment.id, appointment.appointmentSlotId);
                      },
                      icon: Icon(Icons.delete_outline, size: 24),
                      color: Theme.of(context).colorScheme.error,
                      tooltip: 'Delete',
                    ),
                ],
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            );
          },
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    const List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length]; // Deterministic color assignment
  }

  Widget _buildStatusChip(String status, BuildContext context) {
    final Map<String, Color> statusColors = {
      'completed': Theme.of(context).colorScheme.primary,
      'pending': Theme.of(context).colorScheme.secondary,
      'canceled': Theme.of(context).colorScheme.error,
    };
    final color = statusColors[status.toLowerCase()] ?? Colors.grey;

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withAlpha((0.1 * 255).toInt()),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  Widget _buildPaymentStatusChip(String status, BuildContext context) {
    final bool isPaid = status.toLowerCase() == 'paid';
    final color = isPaid
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withAlpha((0.1 * 255).toInt()),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }
}
