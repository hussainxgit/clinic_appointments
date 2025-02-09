import 'package:clinic_appointments/shared/database/mock_data.dart';
import 'package:flutter/material.dart';

import '../models/doctor_availability.dart';

class DoctorAvailabilityProvider extends ChangeNotifier {
  final List<DoctorAvailability> _availabilities = mockDoctorAvailability;

  List<DoctorAvailability> get availabilities => _availabilities;

  // Add a new availability slot
  void createAvailability(DoctorAvailability availability) {
    _availabilities.add(availability);
    notifyListeners();
  }

  // Remove an availability slot
  void removeAvailability(String availabilityId) {
    _availabilities
        .removeWhere((availability) => availability.id == availabilityId);
    notifyListeners();
  }

  // Update an availability slot
  void updateAvailability(DoctorAvailability updatedAvailability) {
    final index =
        _availabilities.indexWhere((a) => a.id == updatedAvailability.id);
    if (index != -1) {
      _availabilities[index] = updatedAvailability;
      notifyListeners();
    }
  }

  // Get all availabilities for a specific doctor
  List<DoctorAvailability> getAvailabilitiesForDoctor(String doctorId) {
    return _availabilities
        .where((availability) => availability.doctorId == doctorId)
        .toList();
  }

  // Check if a doctor is available at a specific date and time
  bool isDoctorAvailable(String doctorId, DateTime date) {
    final availabilities = getAvailabilitiesForDoctor(doctorId);
    for (final availability in availabilities) {
      if (availability.bookedPatients < availability.maxPatients) {
        return true;
      }
    }
    return false;
  }

  void cancelBooking(String availabilityId) {
    final availability = _availabilities.firstWhere(
      (availability) => availability.id == availabilityId,
      orElse: () => throw Exception('Availability not found'),
    );
    availability.cancelBooking();
    notifyListeners();
  }

  void bookPatient(String availabilityId) {
    print(availabilityId);
    final availability = _availabilities.firstWhere(
      (availability) => availability.id == availabilityId,
      orElse: () => throw Exception('Availability not found'),
    );
    availability.bookPatient();
    notifyListeners();
  }

}
