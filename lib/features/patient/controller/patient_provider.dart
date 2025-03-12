import 'package:flutter/material.dart';
import '../../../shared/database/mock_data.dart';
import '../models/patient.dart';

class PatientProvider extends ChangeNotifier {
  // Private list of patients initialized with mock data
  final List<Patient> _patients = allPatients;

  // Getter for patients list
  List<Patient> get patients => List.unmodifiable(_patients);

  // Add a new patient
  Patient addPatient(Patient patient) {
    _patients.add(patient);
    notifyListeners();
    return patient;
  }

  // Remove a patient by ID
  void removePatient(String patientId) {
    _patients.removeWhere((patient) => patient.id == patientId);
    notifyListeners();
  }

  // Update an existing patient
  void updatePatient(Patient updatedPatient) {
    final index = _patients.indexWhere((p) => p.id == updatedPatient.id);
    if (index != -1) {
      _patients[index] = updatedPatient;
      notifyListeners();
    }
  }

  // Search patients by phone number
  List<Patient> searchPatientsByPhone(String phoneQuery) {
    final cleanQuery = phoneQuery.trim().toLowerCase();
    return _patients
        .where((patient) => patient.phone.toLowerCase().contains(cleanQuery))
        .toList();
  }

  // Comprehensive search across name and phone
  List<Patient> searchPatientsByQuery(String searchQuery) {
    final cleanQuery = searchQuery.trim().toLowerCase();
    return _patients
        .where((patient) =>
            patient.name.toLowerCase().contains(cleanQuery) ||
            patient.phone.toLowerCase().contains(cleanQuery))
        .toList();
  }

  // Find patient by phone number
  Patient? findPatientByPhone(String phone) {
    final cleanPhone = phone.trim();
    try {
      return _patients.firstWhere((p) => p.phone == cleanPhone);
    } catch (e) {
      return null;
    }
  }

  // Auto-fill patient name based on phone number
  void autoFillNameFromPhone(
      String phone, TextEditingController nameController) {
    final patient = findPatientByPhone(phone);
    if (patient != null) {
      nameController.text = patient.name;
    }
    notifyListeners();
  }

  // Get total number of patients
  int get patientCount => _patients.length;

  // Filter patients by status
  List<Patient> getPatientsByStatus(PatientStatus status) {
    return _patients.where((patient) => patient.status == status).toList();
  }

  void suspendPatient(String patientId) {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patients[index] =
          _patients[index].copyWith(status: PatientStatus.inactive);
      notifyListeners();
    }
  }

  void activatePatient(String patientId) {
    final index = _patients.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      _patients[index] =
          _patients[index].copyWith(status: PatientStatus.active);
      notifyListeners();
    }
  }
}
