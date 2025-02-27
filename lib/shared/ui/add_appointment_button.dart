import 'package:flutter/material.dart';
import 'package:clinic_appointments/features/appointment/view/add_appointment_dialog.dart';

class AddAppointmentButton extends StatelessWidget {
  const AddAppointmentButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AddAppointmentDialog(),
        );
      },
      child: const Text('Add appointment, patient'),
    );
  }
}