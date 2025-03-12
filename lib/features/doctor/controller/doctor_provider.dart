import 'package:flutter/material.dart';
import '../../../shared/database/mock_data.dart';
import '../models/doctor.dart';
import '../models/doctor_exception.dart';

class DoctorProvider extends ChangeNotifier {
  // Private list of doctors initialized with mock data
  final List<Doctor> _doctors = allDoctors;

  // Getter for the immutable copy of doctors
  List<Doctor> get doctors => List.unmodifiable(_doctors);

  // Add a new doctor with validation
  void addDoctor(Doctor doctor) {
    _validateDoctor(doctor);
    if (_doctors.any((d) => d.id == doctor.id)) {
      throw DuplicateDoctorIdException(doctor.id);
    }
    if (_doctors.any((d) => d.name == doctor.name)) {
      throw DuplicateDoctorException(doctor.name);
    }
    _doctors.add(doctor);
    notifyListeners();
  }

  // Remove a doctor by ID
  void removeDoctor(String doctorId) {
    if (doctorId.isEmpty) {
      throw InvalidDoctorIdException(doctorId);
    }

    final index = _doctors.indexWhere((d) => d.id == doctorId);
    if (index == -1) {
      throw DoctorNotFoundException(doctorId);
    }

    _doctors.removeAt(index);
    notifyListeners();
  }

  // Update an existing doctor
  void updateDoctor(Doctor updatedDoctor) {
    _validateDoctor(updatedDoctor);

    final index = _doctors.indexWhere((d) => d.id == updatedDoctor.id);
    if (index == -1) {
      throw DoctorNotFoundException(updatedDoctor.id);
    }

    // Check for name uniqueness (excluding the current doctor)
    if (_doctors
        .any((d) => d.name == updatedDoctor.name && d.id != updatedDoctor.id)) {
      throw DuplicateDoctorException(updatedDoctor.name);
    }

    _doctors[index] = updatedDoctor;
    notifyListeners();
  }

  // Toggle doctor availability
  void toggleDoctorAvailability(String doctorId) {
    final index = _doctors.indexWhere((d) => d.id == doctorId);
    if (index == -1) {
      throw DoctorNotFoundException(doctorId);
    }

    _doctors[index] =
        _doctors[index].copyWith(isAvailable: !_doctors[index].isAvailable);
    notifyListeners();
  }

  // Search doctors by name, specialty, or phone
  List<Doctor> searchDoctors(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return doctors;

    return _doctors
        .where((doctor) =>
            doctor.name.toLowerCase().contains(cleanQuery) ||
            doctor.specialty.toLowerCase().contains(cleanQuery) ||
            doctor.phoneNumber.toLowerCase().contains(cleanQuery))
        .toList();
  }

  // Filter doctors by specialty
  List<Doctor> getDoctorsBySpecialty(String specialty) {
    return _doctors
        .where((doctor) =>
            doctor.specialty.toLowerCase() == specialty.toLowerCase())
        .toList();
  }

  // Get only available doctors
  List<Doctor> getAvailableDoctors() {
    return _doctors.where((doctor) => doctor.isAvailable).toList();
  }

  // Find doctor by ID
  Doctor? findDoctorById(String id) {
    try {
      return _doctors.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  // Find doctor by phone number
  Doctor? findDoctorByPhone(String phone) {
    try {
      return _doctors.firstWhere((d) => d.phoneNumber == phone);
    } catch (e) {
      return null;
    }
  }

  // Get all specialties (unique)
  List<String> get allSpecialties {
    return _doctors.map((d) => d.specialty).toSet().toList();
  }

  // Get total number of doctors
  int get doctorCount => _doctors.length;

  // Get count of available doctors
  int get availableDoctorCount => getAvailableDoctors().length;

  // Common validation for doctors
  void _validateDoctor(Doctor doctor) {
    if (doctor.id.isEmpty) {
      throw InvalidDoctorIdException(doctor.id);
    }
    if (doctor.name.isEmpty) {
      throw InvalidDoctorNameException(doctor.name);
    }
    if (doctor.specialty.isEmpty) {
      throw InvalidDoctorSpecialtyException(doctor.specialty);
    }
    if (doctor.phoneNumber.isEmpty) {
      throw InvalidDoctorPhoneNumberException(doctor.phoneNumber);
    }
    // Add phone number format validation if needed
  }
}
