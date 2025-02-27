import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../appointment/models/appointment.dart';
import '../../appointment/view/edit_appointment_dialog.dart';
import '../../doctor/models/doctor.dart';
import '../../patient/models/patient.dart';

class PatientAppointmentList extends StatelessWidget {
  final Patient patient;

  const PatientAppointmentList({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicService>(builder: (context, provider, child) {
      final compindeAppointments =
          provider.getCombinedAppointments(patientId: patient.id);

      return compindeAppointments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Appointments (02)',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to view or add appointments.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: compindeAppointments.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final Appointment appointment =
                    compindeAppointments[index]['appointment'];
                final Doctor doctor = compindeAppointments[index]['doctor'];

                return ListTile(
                  title: Text(
                    doctor.name,
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
                        Icon(Icons.date_range_rounded),
                        Text(
                          appointment.dateTime.dateOnly(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        _buildPaymentStatusChip(
                            appointment.paymentStatus, context),
                        _buildStatusChip(appointment.status, context),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (appointment.dateTime.isAfter(DateTime.now()))
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
                              .removeAppointment(appointment.id,
                                  appointment.appointmentSlotId);
                        },
                        icon: Icon(Icons.delete_outline, size: 24),
                        color: Theme.of(context).colorScheme.error,
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                );
              },
            );
    });
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
      backgroundColor: color.withOpacity(0.1),
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
      backgroundColor: color.withOpacity(0.1),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }
}
