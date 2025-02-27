import 'package:clinic_appointments/features/appointment_slot/view/appointment_slot_list_view.dart';
import 'package:flutter/material.dart';
import 'create_appointment_slot_dialog.dart';

class AppointmentSlotScreen extends StatelessWidget {
  const AppointmentSlotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) => CreateAppointmentSlot());
                },
                child: Text('Create Appointment Slot')),
            AppointmentSlotListView(),
          ],
        ),
      ),
    );
  }
}
