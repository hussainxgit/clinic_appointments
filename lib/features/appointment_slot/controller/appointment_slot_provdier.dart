import '/shared/database/mock_data.dart';
import 'package:flutter/foundation.dart';

import '../models/appointment_slot.dart';

class AppointmentSlotProvider extends ChangeNotifier {
  final List<AppointmentSlot> _slots = mockAppointmentSlots;

  List<AppointmentSlot> get slots => List.unmodifiable(_slots);

  // Add a new appointment slot
  void createAppointmentSlot(AppointmentSlot appointment) {
    _slots.add(appointment);
    notifyListeners();
  }

  // Remove an appointment slot
  void removeAppointmentSlot(String appointmentId) {
    _slots.removeWhere((appointment) => appointment.id == appointmentId);
    notifyListeners();
  }

  // Update an appointment slot
  void updateAppointmentSlot(AppointmentSlot updatedAppointmentSlot) {
    final index = _slots.indexWhere((a) => a.id == updatedAppointmentSlot.id);
    if (index != -1) {
      _slots[index] = updatedAppointmentSlot;
      notifyListeners();
    }
  }

  // Get all appointments for a specific doctor
  List<AppointmentSlot> getAppointmentSlotsForDoctor(String doctorId) {
    return _slots
        .where((appointment) => appointment.doctorId == doctorId)
        .toList();
  }

  // Check if a doctor is available at a specific date and time
  bool isDoctorAvailable(String doctorId, DateTime date) {
    final appointmentSlots = getAppointmentSlotsForDoctor(doctorId);
    for (final appointmentSlot in appointmentSlots) {
      if (appointmentSlot.bookedPatients < appointmentSlot.maxPatients) {
        return true;
      }
    }
    return false;
  }

  void cancelBooking(String appointmentId) {
    final appointment = _slots.firstWhere(
      (appointment) => appointment.id == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );
    appointment.cancelBooking();
    notifyListeners();
  }

  void bookPatient(String appointmentId) {
    final appointment = _slots.firstWhere(
      (appointment) => appointment.id == appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );
    appointment.bookPatient(); // This modifies the state of the appointment
    notifyListeners(); // Notify listeners after the state change
  }

  void updateSlot(
      String slotId, AppointmentSlot Function(AppointmentSlot) update) {
    final index = _slots.indexWhere((s) => s.id == slotId);
    if (index != -1) {
      _slots[index] = update(_slots[index]);
      notifyListeners();
    }
  }

  void bookSlot(String slotId) {
    updateSlot(slotId, (slot) => slot.bookPatient());
  }

  void cancelSlot(String slotId) {
    updateSlot(slotId, (slot) => slot.cancelBooking());
  }

  List<AppointmentSlot> getDoctorSlots(String doctorId) =>
      _slots.where((s) => s.doctorId == doctorId).toList();
}
