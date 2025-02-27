import 'package:flutter/material.dart';
import '../../../shared/database/mock_data.dart';
import '../models/doctor.dart';
import '../models/doctor_exception.dart';

class DoctorProvider extends ChangeNotifier {
  final List<Doctor> _doctors = mockDoctors;

  /// Mutable list of doctors (returns a copy to maintain immutability for external access)
  List<Doctor> get doctors => List.unmodifiable(_doctors);

  /// Add a new doctor with validation
  void addDoctor(Doctor doctor) {
    _validateDoctor(doctor); // Common validation
    if (_doctors
        .any((d) => d.id == doctor.id || d.phoneNumber == doctor.phoneNumber)) {
      throw DuplicateDoctorException(doctor.name);
    }
    _doctors.add(doctor);
    notifyListeners();
  }

  /// Remove an existing doctor
  void removeDoctor(String doctorId) {
    final doctor = _doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => throw DoctorNotFoundException(doctorId),
    );
    _doctors.removeWhere((d) => d.id == doctorId);
    notifyListeners();
  }

  /// Update an existing doctor
  void updateDoctor(Doctor updated) {
    _validateDoctor(updated); // Validate updated doctor
    final index = _doctors.indexWhere((d) => d.id == updated.id);
    if (index == -1) throw DoctorNotFoundException(updated.id);
    _doctors[index] = updated;
    notifyListeners();
  }

  /// Get all doctors (redundant with 'doctors' getter, but kept for clarity)
  List<Doctor> getAllDoctors() {
    return List.unmodifiable(_doctors);
  }

  /// Get available doctors
  List<Doctor> getAvailableDoctors() {
    return _doctors.where((doctor) => doctor.isAvailable).toList();
  }

  /// Common validation for doctors
  void _validateDoctor(Doctor doctor) {
    if (doctor.id.isEmpty) {
      throw InvalidDoctorDataException('Doctor ID cannot be empty');
    }
    if (doctor.name.isEmpty) {
      throw InvalidDoctorDataException('Doctor name cannot be empty');
    }
    if (doctor.phoneNumber.isEmpty) {
      throw InvalidDoctorDataException('Phone number cannot be empty');
    }
    if (doctor.specialty.isEmpty) {
      throw InvalidDoctorDataException('Specialty cannot be empty');
    }
    if (doctor.phoneNumber.length > 8) {
      throw InvalidDoctorPhoneNumberException(doctor.phoneNumber);
    }
    if (doctor.specialty.length < 3) {
      throw InvalidDoctorSpecialtyException(doctor.specialty);
    }
    if (doctor.name.length < 3) {
      throw InvalidDoctorNameException(doctor.name);
    }
  }
}
