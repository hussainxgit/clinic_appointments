import 'package:flutter/material.dart';
import '../models/appointment_slot.dart';
import '../models/slot_exception.dart';
import '/shared/database/mock_data.dart';

class AppointmentSlotProvider extends ChangeNotifier {
  final List<AppointmentSlot> _slots = mockAppointmentSlots;

  /// Immutable copy of slots
  List<AppointmentSlot> get slots => List.unmodifiable(_slots);

  /// Get slots for a specific doctor with optional date filter
  List<AppointmentSlot> getSlots({String? doctorId, DateTime? date}) {
    return _slots.where((slot) {
      final doctorMatch = doctorId == null || slot.doctorId == doctorId;
      final dateMatch = date == null || _isSameDate(slot.date, date);
      return doctorMatch && dateMatch;
    }).toList();
  }

  /// Check doctor availability for specific date
  bool isDoctorAvailable(String doctorId, DateTime date) {
    return getSlots(doctorId: doctorId, date: date)
        .any((slot) => !slot.isFullyBooked);
  }

  /// Generic slot update method
  void updateSlot(
      String slotId, AppointmentSlot Function(AppointmentSlot) update) {
    final index = _slots.indexWhere((s) => s.id == slotId);
    if (index == -1) throw SlotNotFoundException(slotId);

    final updatedSlot = update(_slots[index]);
    _validateSlot(updatedSlot); // Validate updated slot
    _slots[index] = updatedSlot;
    notifyListeners();
  }

  /// Book a slot (immutable update)
  void bookSlot(String slotId) {
    updateSlot(slotId, (slot) {
      if (slot.isFullyBooked) throw SlotFullyBookedException(slotId);
      if (slot.date.isBefore(DateTime.now())) {
        throw SlotDateInPastException(slot.date);
      }
      return slot.bookPatient();
    });
  }

  /// Cancel booking (immutable update)
  void cancelSlot(String slotId) {
    updateSlot(slotId, (slot) {
      if (slot.bookedPatients <= 0) throw SlotNotBookedException(slotId);
      return slot.cancelBooking();
    });
  }

  /// Add new slot with validation
  void addSlot(AppointmentSlot newSlot) {
    _validateSlot(newSlot); // Common validation
    if (_slots.any((s) => s.id == newSlot.id)) {
      throw DuplicateSlotIdException(newSlot.id);
    }
    if (_slots.any((s) =>
        s.doctorId == newSlot.doctorId && _isSameDate(s.date, newSlot.date))) {
      throw SameDaySlotException(newSlot.doctorId, newSlot.date);
    }
    _slots.add(newSlot);
    notifyListeners();
  }

  /// Remove existing slot
  void removeSlot(String slotId) {
    final slot = _slots.firstWhere(
      (s) => s.id == slotId,
      orElse: () => throw SlotNotFoundException(slotId),
    );
    if (slot.bookedPatients > 0) {
      throw SlotHasBookingsException(slotId);
    }
    if (slot.date.isBefore(DateTime.now())) {
      throw SlotDateInPastException(slot.date); // Prevent removing past slots
    }
    _slots.removeWhere((s) => s.id == slotId);
    notifyListeners();
  }

  /// Helper for date comparison
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Select a slot date for a doctor
  Future<Map<String, dynamic>?> selectSlotForDoctor(
      BuildContext context, String doctorId) async {
    final slots = getSlots(doctorId: doctorId)
        .where(
            (slot) => !slot.isFullyBooked && slot.date.isAfter(DateTime.now()))
        .toList();
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No available dates for this doctor'),
            backgroundColor: Colors.red),
      );
      return null;
    }

    final dates = slots.map((s) => s.date).toList();
    final initialDate =
        dates.contains(DateTime.now()) ? DateTime.now() : dates.first;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      selectableDayPredicate: (day) => dates.any((d) => _isSameDate(d, day)),
    );

    if (picked != null) {
      final selectedSlot = slots.firstWhere((s) => _isSameDate(s.date, picked));
      notifyListeners();
      return {'date': picked, 'slotId': selectedSlot.id};
    }
    return null;
  }

  /// Common validation for slots
  void _validateSlot(AppointmentSlot slot) {
    if (slot.doctorId.isEmpty) {
      throw InvalidSlotDataException('Doctor ID cannot be empty');
    }
    if (slot.maxPatients <= 0) {
      throw InvalidSlotDataException('Max patients must be greater than 0');
    }
    if (slot.bookedPatients < 0) {
      throw InvalidSlotDataException('Booked patients cannot be negative');
    }
    if (slot.bookedPatients > slot.maxPatients) {
      throw InvalidSlotDataException(
          'Booked patients cannot exceed max patients');
    }
    if (slot.date.isBefore(DateTime.now())) {
      throw SlotDateInPastException(slot.date);
    }
  }
}
