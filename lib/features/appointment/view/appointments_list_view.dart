import 'package:clinic_appointments/features/appointment/view/appointment_card.dart';
import 'package:flutter/material.dart';
import '../../doctor/models/doctor.dart';
import '../../patient/models/patient.dart';
import '../models/appointment.dart';

class AppointmentsGridView extends StatelessWidget {
  final List<Map<String, dynamic>> combinedAppointments;

  const AppointmentsGridView({super.key, required this.combinedAppointments});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300, // Adaptive width for cards
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: combinedAppointments.length,
          itemBuilder: (context, index) {
            final appointment =
                combinedAppointments[index]['appointment'] as Appointment;
            final patient = combinedAppointments[index]['patient'] as Patient;
            final doctor = combinedAppointments[index]['doctor'] as Doctor;

            return AppointmentCard(
                appointment: appointment,
                patient: patient,
                doctor: doctor,
                index: index);
          },
        ),
      ),
    );
  }

 
}
