import 'package:clinic_appointments/shared/database/mock_data.dart';
import 'package:flutter/material.dart';
import '../../patient/models/patient.dart';
import '../models/appointment.dart';

class AppointmentProvider extends ChangeNotifier {
  final List<Appointment> _appointments = mockAppointments;

  List<Appointment> get appointments => List.unmodifiable(_appointments);

  void addAppointment(Appointment appointment) {
    _appointments.add(appointment);
    notifyListeners();
  }

  void removeAppointment(String appointmentId) {
    _appointments.removeWhere((a) => a.id == appointmentId);
    notifyListeners();
  }

  void updateAppointment(Appointment updated) {
    final index = _appointments.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      _appointments[index] = updated;
      notifyListeners();
    }
  }

  void updatePatientInAppointments(Patient patient) {
    bool needsUpdate = false;
    final List<Appointment> updated = _appointments.map<Appointment>((a) {
      if (a.patientId== patient.id) {
        needsUpdate = true;
        return a.copyWith(patient: patient);
      }
      return a;
    }).toList();

    if (needsUpdate) {
      _appointments
        ..clear()
        ..addAll(updated);
      notifyListeners();
    }
  }

}
