import 'package:clinic_appointments/shared/database/mock_data.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/appointment_exception.dart';

class AppointmentProvider extends ChangeNotifier {
  final List<Appointment> _appointments = mockAppointments;

  /// Immutable copy of appointments
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  /// Add a new appointment with validation
  void addAppointment(Appointment appointment) {
    _validateAppointment(appointment); // Common validation
    if (_appointments.any((a) => a.id == appointment.id)) {
      throw DuplicateAppointmentIdException(appointment.id);
    }
    // Check for double booking on the same day
    if (_appointments.any((a) =>
        a.patientId == appointment.patientId &&
        appointment.dateTime.isSameDay(a.dateTime))) {
      throw DuplicatePatientAppointmentException(
          appointment.patientId, appointment.dateTime);
    }
    _appointments.add(appointment);
    notifyListeners();
  }

  /// Remove an existing appointment
  void removeAppointment(String appointmentId) {
    final appointment = _appointments.firstWhere(
      (a) => a.id == appointmentId,
      orElse: () => throw AppointmentNotFoundException(appointmentId),
    );
    if (appointment.dateTime.isBefore(DateTime.now())) {
      throw AppointmentDateInPastException(
          appointment.dateTime); // Prevent removing past appointments
    }
    _appointments.removeWhere((a) => a.id == appointmentId);
    notifyListeners();
  }

  /// Update an existing appointment
  void updateAppointment(Appointment updated) {
    _validateAppointment(updated); // Validate updated appointment
    final index = _appointments.indexWhere((a) => a.id == updated.id);
    if (index == -1) throw AppointmentNotFoundException(updated.id);
    // Check for double booking on update, excluding the current appointment being updated
    if (_appointments.any((a) =>
        a.id != updated.id &&
        a.patientId == updated.patientId &&
        a.dateTime.isSameDay(updated.dateTime))) {
      throw DuplicatePatientAppointmentException(
          updated.patientId, updated.dateTime);
    }
    _appointments[index] = updated;
    notifyListeners();
  }

  /// Get appointments by patient IDs
  List<Appointment> getAppointmentsByPatientIds(List<String> patientIds) {
    if (patientIds.isEmpty) {
      throw InvalidAppointmentDataException('Patient IDs list cannot be empty');
    }
    return _appointments
        .where((appointment) => patientIds.contains(appointment.patientId))
        .toList();
  }

  /// Common validation for appointments
  void _validateAppointment(Appointment appointment) {
    if (appointment.id.isEmpty) {
      throw InvalidAppointmentDataException('Appointment ID cannot be empty');
    }
    if (appointment.patientId.isEmpty) {
      throw InvalidAppointmentDataException('Patient ID cannot be empty');
    }
    if (appointment.doctorId.isEmpty) {
      throw InvalidAppointmentDataException('Doctor ID cannot be empty');
    }
    if (appointment.appointmentSlotId.isEmpty) {
      throw InvalidAppointmentDataException(
          'Appointment slot ID cannot be empty');
    }
    if (appointment.dateTime.isBefore(DateTime.now())) {
      throw AppointmentDateInPastException(appointment.dateTime);
    }
    if (appointment.status.isEmpty) {
      throw InvalidAppointmentDataException('Status cannot be empty');
    }
    if (appointment.paymentStatus.isEmpty) {
      throw InvalidAppointmentDataException('Payment status cannot be empty');
    }
  }
}
