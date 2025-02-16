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
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: combinedAppointments.length,
        itemBuilder: (context, index) {
          final appointment =
              combinedAppointments[index]['appointment'] as Appointment;
          final patient = combinedAppointments[index]['patient'] as Patient;
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallScreen = constraints.maxWidth < 600;
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      'Patient: ${patient.name}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Appointment: ${appointment.dateTime.dateOnly()} - ${appointment.status}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                appointment.patientId,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildPaymentStatusChip(
                                      appointment.paymentStatus),
                                  const SizedBox(width: 8),
                                  _buildStatusChip(appointment.status),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Text(
                                'Appointment: ${appointment.dateTime.dateOnly()}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                appointment.patientId,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 16),
                              _buildPaymentStatusChip(
                                  appointment.paymentStatus),
                              const SizedBox(width: 8),
                              _buildStatusChip(appointment.status),
                            ],
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () {
                            Provider.of<ClinicService>(context, listen: false)
                                .removeAppointment(appointment.id,
                                    appointment.appointmentSlotId);
                          },
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                  if (index < combinedAppointments.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'canceled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }

  static Widget _buildPaymentStatusChip(String status) {
    Color color = (status.toLowerCase() == 'paid') ? Colors.green : Colors.red;
    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      side: BorderSide.none,
    );
  }
}
