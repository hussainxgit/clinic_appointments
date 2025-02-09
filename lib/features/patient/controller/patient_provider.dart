import 'package:clinic_appointments/shared/database/mock_data.dart';
import 'package:flutter/foundation.dart';

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
}
