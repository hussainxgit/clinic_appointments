import 'package:clinic_appointments/shared/database/mock_data.dart';
import 'package:flutter/material.dart';

import '../models/patient.dart';

class PatientProvider with ChangeNotifier {
  //TODO: mock data
  final List<Patient> _patients = mockPatients;

  List<Patient> get patients => _patients;

  void addPatient(Patient patient) {
    _patients.add(patient);
    notifyListeners();
  }

  void removePatient(String patientId) {
    _patients.removeWhere((patient) => patient.id == patientId);
    notifyListeners();
  }

  void updatePatient(Patient patient) {
    final index = _patients.indexWhere((p) => p.id == patient.id);
    if (index != -1) {
      _patients[index] = patient;
      notifyListeners();
    }
  }

  List<Patient> searchPatientsByPhone(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];
    return _patients
        .where((patient) => patient.phone.toLowerCase().contains(cleanQuery))
        .toList();
  }

  // New: Auto-fill patient name based on phone number
  void updateNameFromPhone(String phone, TextEditingController nameController) {
    final patient = _patients.firstWhere(
      (p) => p.phone == phone.trim(),
      orElse: () =>
          Patient(id: '', name: '', phone: '', registeredAt: DateTime.now()),
    );
    if (patient.id.isNotEmpty) {
      nameController.text = patient.name;
    }
    notifyListeners();
  }
}
