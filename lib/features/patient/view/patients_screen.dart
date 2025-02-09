import 'package:clinic_appointments/features/patient/view/patients_list_view.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ClinicService>(builder: (context, patientProvider, child) {
        return PatientsListView(
            patients: patientProvider.patientProvider.patients);
      }),
    );
  }
}
