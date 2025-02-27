import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment_slot.dart';
import 'edit_appointment_slot_dialog.dart';

class AppointmentSlotListView extends StatelessWidget {

  const AppointmentSlotListView({super.key,});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Consistent spacing
      child: Card(
        elevation: 2, // Subtle elevation per Material 3
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Softer corners
        ),
        child: Consumer<ClinicService>(builder: (context, clinicService, child){
          List<AppointmentSlot> appointmentSlots = clinicService.getAllAppointmentSlots();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Nested scrolling
              itemCount: appointmentSlots.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final appointment = appointmentSlots[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    leading: _buildStatusChip(context, appointment),
                    title: Text(
                      appointment.date.dateOnly(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600, // Bold but not too heavy
                          ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Booked: ${appointment.bookedPatients}/${appointment.maxPatients}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (appointment.date.isAfter(DateTime.now()) ||
                            appointment.date.isSameDay(DateTime.now()))
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    EditAppointmentSlot(initialSlot: appointment),
                              );
                            },
                            icon: Icon(Icons.edit_outlined, size: 24),
                            color: Theme.of(context).colorScheme.primary,
                            tooltip: 'Edit',
                          ),
                        IconButton(
                          onPressed: () {
                            Provider.of<ClinicService>(context, listen: false)
                                .removeAppointmentSlot(appointment.id);
                          },
                          icon: Icon(Icons.delete_outline, size: 24),
                          color: Theme.of(context).colorScheme.error,
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                );
              },
            );
          }
        ),
      ),
    );
  }

  Widget _buildStatusChip(context, AppointmentSlot appointment) {
    final DateTime now = DateTime.now();
    final DateTime appointmentDate = appointment.date;
    final DateTime today = DateTime(now.year, now.month, now.day);

    String label;
    Color color;

    if (appointmentDate.isBefore(today)) {
      label = 'Done';
      color = Colors.grey;
    } else if (appointment.bookedPatients >= appointment.maxPatients) {
      label = 'Full';
      color = Theme.of(context).colorScheme.error;
    } else if (appointmentDate.isSameDay(today)) {
      label = 'Today';
      color = Theme.of(context).colorScheme.secondary;
    } else if (appointment.bookedPatients > 0) {
      label = 'Partially Booked';
      color = Theme.of(context).colorScheme.tertiary;
    } else {
      label = 'Available';
      color = Theme.of(context).colorScheme.primary;
    }

    return Chip(
      label: Text(label.toUpperCase()),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}
