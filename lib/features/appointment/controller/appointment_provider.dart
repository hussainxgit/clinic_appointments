import 'package:clinic_appointments/shared/database/mock_data.dart';
import 'package:flutter/material.dart';
import '../../patient/models/patient.dart';
import '../models/appointment.dart';

class AppointmentProvider extends ChangeNotifier {
  final List<Appointment> _appointments = mockAppointments;

  List<Appointment> get appointments => _appointments;

  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    notifyListeners(); // Add this
  }

  void removeAppointment(String appointmentId) {
    _appointments.removeWhere((appointment) => appointment.id == appointmentId);
    notifyListeners(); // Add this
  }

  void updateAppointment(Appointment appointment) {
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    _appointments[index] = appointment;
    notifyListeners(); // Add this
  }

  // ✅ New: Update all appointments with the new patient data
  void updateAppointmentPatient(Patient updatedPatient) {
    for (var appointment in _appointments) {
      if (appointment.patient.id == updatedPatient.id) {
        appointment.patient = updatedPatient; // Update reference
      }
    }
    notifyListeners(); // Notify UI about changes
  }
}
