import 'package:clinic_appointments/features/appointment_slot/view/appointment_slot_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/provider/clinic_service.dart';
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
            Consumer<ClinicService>(builder: (context, clinicService, child) {
              return AppointmentSlotListView(
                  appointmentSlots: clinicService
                      .getAllAppointmentSlotsForDoctor('D1')); //todo: fix this
            }),
          ],
        ),
      ),
    );
  }
}

