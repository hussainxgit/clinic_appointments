import 'package:flutter/material.dart';

import '../../../shared/database/mock_data.dart';
import '../models/doctor.dart';

class DoctorProvider extends ChangeNotifier {
  final List<Doctor> _doctors = mockDoctors;

  List<Doctor> get doctors => _doctors;

  void addDoctor(Doctor doctor) {
    _doctors.add(doctor);
    notifyListeners();
  }

  void removeDoctor(String doctorId) {
    _doctors.removeWhere((doctor) => doctor.id == doctorId);
    notifyListeners();
  }

  void updateDoctor(Doctor doctor) {
    final index = _doctors.indexWhere((d) => d.id == doctor.id);
    _doctors[index] = doctor;
    notifyListeners();
  }

  List<Doctor> getAllDoctors() {
    return _doctors;
  }

  List<Doctor> getAvailableDoctors() {
    return _doctors.where((doctor) => doctor.isAvailable).toList();
  }

}

