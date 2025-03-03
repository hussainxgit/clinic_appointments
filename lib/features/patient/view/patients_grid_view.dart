import 'package:flutter/material.dart';
import '../models/patient.dart';
import 'patient_card.dart';

// Refactored grid view for displaying Patients
class PatientsGridView extends StatelessWidget {
  final List<Patient> patients;

  const PatientsGridView({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: patients.length,
      itemBuilder: (context, index) => PatientCard(
        patient: patients[index],
        index: index,
      ),
    );
  }
}
