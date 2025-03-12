import 'package:clinic_appointments/features/appointment/view/add_appointment_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/features/appointment/models/appointment.dart';
import 'package:clinic_appointments/features/patient/models/patient.dart';
import 'package:clinic_appointments/features/doctor/models/doctor.dart';
import 'package:clinic_appointments/features/appointment/view/appointment_details_screen.dart';
import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'appointment_list_item.dart';
import 'dashboard_empty_state.dart';

class DashboardAppointmentsList extends StatelessWidget {
  final DateTime selectedDate;

  const DashboardAppointmentsList({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        final appointments =
            clinicService.getCombinedAppointmentsByDate(selectedDate);
        if (appointments.isEmpty) {
          return DashboardEmptyState(
            message: 'No appointments for this date',
            icon: Icons.event_busy,
            buttonText: 'Add Appointment',
            onButtonPressed: () {
              showDialog(context: context, builder: (context)=> AddAppointmentDialog());
            },
          );
        }
        return ListView.separated(
          itemCount: appointments.length,
          shrinkWrap: true,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final appointment =
                appointments[index]['appointment'] as Appointment;
            final patient = appointments[index]['patient'] as Patient;
            final doctor = appointments[index]['doctor'] as Doctor;
            return AppointmentListItem(
              appointment: appointment,
              patient: patient,
              doctor: doctor,
              onEdit: () {},
              onDelete: () => clinicService.removeAppointment(appointment.id),
              onViewDetails: () => {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AppointmentDetailsScreen(appointmentId: appointment.id),
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