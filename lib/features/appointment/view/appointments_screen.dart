import 'package:clinic_appointments/features/appointment/view/appointments_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/provider/clinic_service.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ClinicService>(
          builder: (context, appointmentProvider, child) {
        return AppointmentsListView(
            appointments: appointmentProvider.appointmentProvider.appointments);
      }),
    );
  }
}
