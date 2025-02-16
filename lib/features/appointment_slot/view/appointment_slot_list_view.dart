import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment_slot.dart';
import 'edit_appointment_slot_dialog.dart';

class AppointmentSlotListView extends StatelessWidget {
  final List<AppointmentSlot> appointmentSlots;

  const AppointmentSlotListView({super.key, required this.appointmentSlots});

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
        itemCount: appointmentSlots.length,
        itemBuilder: (context, index) {
          final appointment = appointmentSlots[index];
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmallScreen = constraints.maxWidth < 600;
              return Column(
                children: [
                  ListTile(
                    title: Text(
                      'Date: ${appointment.date.dateOnly()}',
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
                                'Booked slots: ${appointment.bookedPatients}/${appointment.maxPatients}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              _buildStatusChip(appointment),
                            ],
                          )
                        : Row(
                            children: [
                              Text(
                                'Booked slots: ${appointment.bookedPatients}/${appointment.maxPatients}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(appointment),
                            ],
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return EditAppointmentSlot(
                                      initialSlot: appointment);
                                });
                          },
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () {
                            Provider.of<ClinicService>(context, listen: false)
                                .removeAppointmentSlot(appointment.id);
                          },
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                  if (index < appointmentSlots.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(AppointmentSlot appointment) {
    final DateTime now = DateTime.now();
    final DateTime appointmentDate = appointment.date;
    final DateTime today = DateTime(now.year, now.month, now.day);

    final List<String> statuses = [];
    final List<Color> colors = [];

    if (appointmentDate.isBefore(today)) {
      statuses.add('DONE');
      colors.add(Colors.grey);
    } else {
      if (appointment.bookedPatients >= appointment.maxPatients) {
        statuses.add('FULL');
        colors.add(Colors.red);
      }
      if (appointmentDate.isSameDay(today)) {
        statuses.add('TODAY');
        colors.add(Colors.orange);
      }
      if (appointment.bookedPatients > 0 &&
          appointment.bookedPatients < appointment.maxPatients) {
        statuses.add('PARTIALLY BOOKED');
        colors.add(Colors.orange);
      }
      if (appointmentDate.isWithinNextWeek(today)) {
        statuses.add('UPCOMING');
        colors.add(Colors.blue);
      }
      if (statuses.isEmpty) {
        statuses.add('AVAILABLE');
        colors.add(Colors.green);
      }
    }

    return Wrap(
        spacing: 8.0,
        children: List<Widget>.generate(statuses.length, (index) {
          return Chip(
            label: Text(statuses[index]),
            backgroundColor: colors[index].withOpacity(0.2),
            labelStyle: TextStyle(color: colors[index]),
            side: BorderSide.none,
          );
        }));
  }
}
