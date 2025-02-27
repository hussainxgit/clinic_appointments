import 'package:clinic_appointments/features/doctor/view/add_doctor_dialog.dart';
import 'package:clinic_appointments/features/doctor/view/doctors_list_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/provider/clinic_service.dart';

class DoctorsScreen extends StatelessWidget {
  const DoctorsScreen({super.key});

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
                      builder: (context) => AddDoctorDialog());
                },
                child: Text('Add Doctor')),
            Consumer<ClinicService>(
                builder: (context, clinicServiceProvider, child) {
              return DoctorsListView(doctors: clinicServiceProvider.doctorProvider.getAllDoctors(),);
            }),
          ],
        ),
      ),
    );
  }
}
