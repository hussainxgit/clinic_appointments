import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/features/appointment_slot/models/appointment_slot.dart';
import 'package:clinic_appointments/features/doctor/models/doctor.dart';
import 'package:clinic_appointments/features/appointment_slot/view/appointment_slot_patients_screen.dart';
import 'package:clinic_appointments/shared/services/clinic_service.dart';
import '../../appointment_slot/view/create_appointment_slot_dialog.dart';
import '../../appointment_slot/view/slot_list_item.dart';
import 'dashboard_empty_state.dart';

class DashboardSlotsList extends StatelessWidget {
  final DateTime selectedDate;

  const DashboardSlotsList({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        final combinedSlots =
            clinicService.getCombinedSlotsWithDoctors(date: selectedDate);
        if (combinedSlots.isEmpty) {
          return DashboardEmptyState(
            message: 'No slots for this date',
            icon: Icons.calendar_month_outlined,
            buttonText: 'Create Slot',
            onButtonPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CreateAppointmentSlot(),
              );
            },
          );
        }
        return ListView.separated(
          itemCount: combinedSlots.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final slot = combinedSlots[index]['slot'] as AppointmentSlot;
            final doctor = combinedSlots[index]['doctor'] as Doctor;
            return SlotListItem(
              slot: slot,
              doctor: doctor,
              onEdit: () {},
              onDelete: () => clinicService.removeAppointmentSlot(slot.id),
              onViewDetails: () => {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AppointmentSlotPatientsScreen(slot: slot),
                  ),
                )
              },
            );
          },
        );
      },
    );
  }
}