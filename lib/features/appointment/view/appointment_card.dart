import 'package:clinic_appointments/features/doctor/models/doctor.dart';
import 'package:clinic_appointments/features/patient/models/patient.dart';
import 'package:clinic_appointments/features/patient/view/patient_avatar.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../doctor/view/doctor_avatar.dart';
import '../models/appointment.dart';
import 'edit_appointment_dialog.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final Doctor doctor;
  final Patient patient;
  final int index;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.doctor,
    required this.patient,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine if appointment is in the past
    final bool isPast = appointment.dateTime.isBefore(DateTime.now());

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPast
              ? colorScheme.outlineVariant.withOpacity(0.5)
              : colorScheme.primaryContainer,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // Show appointment details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Viewing details for ${patient.name}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(context),
              const SizedBox(height: 16.0),
              _buildAppointmentInfo(theme, colorScheme),
              const Spacer(),
              _buildStatusChip(colorScheme, isPast),
              const SizedBox(height: 12.0),
              _buildActionButtons(context, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              PatientAvatar(
                name: patient.name,
                index: index,
                radius: 24.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      patient.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildMenuButton(context),
      ],
    );
  }

  Widget _buildAppointmentInfo(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date and time section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                appointment.dateTime.dateOnly(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Doctor section
        Text(
          'Doctor',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            DoctorAvatar(
              imageUrl: doctor.imageUrl,
              name: doctor.name,
              index: index,
              radius: 16.0,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    doctor.specialty,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(ColorScheme colorScheme, bool isPast) {
    Color chipColor;
    Color textColor;
    String statusText;
    IconData statusIcon;

    if (isPast) {
      chipColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
      statusText = 'Completed';
      statusIcon = Icons.check_circle_outline;
    } else {
      chipColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
      statusText = 'Upcoming';
      statusIcon = Icons.upcoming_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    final bool isPast = appointment.dateTime.isBefore(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Contact section
        isPast
            ? SizedBox.shrink()
            : Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () {
                      // Message action
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Messaging patient...')),
                      );
                    },
                    icon: const Icon(Icons.message_rounded, size: 18),
                    tooltip: 'Message patient',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),

        // Main action button
        isPast
            ? FilledButton.icon(
                onPressed: () {
                  // View report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing medical report...')),
                  );
                },
                icon: const Icon(Icons.description_rounded, size: 18),
                label: const Text('Notes'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              )
            : FilledButton.icon(
                onPressed: () {
                  // Reschedule appointment
                  showDialog(
                      context: context,
                      builder: (context) {
                        return EditAppointmentDialog(
                          appointment: appointment,
                          patientName: patient.name,
                        );
                      });
                },
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: const Text('Reschedule'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
      ],
    );
  }

  PopupMenuButton<String> _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'More options',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      position: PopupMenuPosition.under,
      onSelected: (String value) {
        switch (value) {
          case 'delete':
            _showDeleteConfirmation(context);
            break;
          case 'edit':
            showDialog(
              context: context,
              builder: (context) => EditAppointmentDialog(
                appointment: appointment,
                patientName: patient.name,
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 12),
              const Text('Edit Appointment'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(
                Icons.delete_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Appointment',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: Text(
            'Are you sure you want to delete the appointment with ${patient.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Provider.of<ClinicService>(context, listen: false)
                    .removeAppointment(
                  appointment.id,
                  appointment.appointmentSlotId,
                );
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
