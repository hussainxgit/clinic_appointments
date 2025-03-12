import 'package:clinic_appointments/features/doctor/view/add_doctor_dialog.dart';
import 'package:clinic_appointments/features/patient/view/add_patient_modal.dart';
import 'package:flutter/material.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';

import '../../appointment/view/add_appointment_dialog.dart';
import '../../appointment_slot/view/create_appointment_slot_dialog.dart';

class DashboardQuickAddDialog extends StatelessWidget {
  const DashboardQuickAddDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallScreen;

    return AlertDialog(
      title: const Text('Quick Add'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isSmall ? 300 : 400,
          maxHeight: isSmall ? 250 : 300,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Add Appointment'),
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => const AddAppointmentDialog()),
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Add Appointment Slot'),
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => const CreateAppointmentSlot()),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Patient'),
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => const AddPatientDialog()),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Add Doctor'),
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => const AddDoctorDialog()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
