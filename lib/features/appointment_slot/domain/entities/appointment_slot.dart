// lib/features/appointment_slot/domain/entities/appointment_slot.dart
import 'time_slot.dart';

class AppointmentSlot {
  final String id;
  final String doctorId;
  final DateTime date;
  final List<TimeSlot> timeSlots;
  final bool isActive;

  const AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.timeSlots,
    this.isActive = true,
  });

  bool get hasBookedPatients =>
      timeSlots.any((slot) => slot.bookedPatients > 0);

  int get totalBookedPatients =>
      timeSlots.fold(0, (sum, slot) => sum + slot.bookedPatients);

  AppointmentSlot copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    List<TimeSlot>? timeSlots,
    bool? isActive,
  }) {
    return AppointmentSlot(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      timeSlots: timeSlots ?? this.timeSlots,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'date': date.toIso8601String(),
      'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
      'isActive': isActive,
    };
  }

  factory AppointmentSlot.fromMap(Map<String, dynamic> map) {
    return AppointmentSlot(
      id: map['id'] as String,
      doctorId: map['doctorId'] as String,
      date: DateTime.parse(map['date'] as String),
      timeSlots:
          (map['timeSlots'] as List)
              .map((slot) => TimeSlot.fromMap(slot as Map<String, dynamic>))
              .toList(),
      isActive: map['isActive'] as bool,
    );
  }

  // Helper methods
  TimeSlot? findTimeSlotById(String timeSlotId) {
    return timeSlots.firstWhere(
      (slot) => slot.id == timeSlotId,
      orElse: () => throw StateError('TimeSlot not found'),
    );
  }

  AppointmentSlot updateTimeSlot(TimeSlot updatedSlot) {
    return copyWith(
      timeSlots:
          timeSlots
              .map((slot) => slot.id == updatedSlot.id ? updatedSlot : slot)
              .toList(),
    );
  }

  List<TimeSlot> get availableTimeSlots =>
      timeSlots.where((slot) => slot.isAvailable).toList();
  bool get isFullyBooked =>
      timeSlots.isNotEmpty && timeSlots.every((slot) => slot.isFullyBooked);

  /// Books an appointment in a specific time slot
  /// Throws exceptions if booking is not possible
  AppointmentSlot bookAppointment(String timeSlotId, String appointmentId) {
    if (!isActive) {
      throw StateError('Cannot book appointment in inactive slot');
    }

    if (date.isBefore(DateTime.now())) {
      throw StateError('Cannot book appointment for past date');
    }

    final timeSlotIndex = timeSlots.indexWhere((ts) => ts.id == timeSlotId);
    if (timeSlotIndex == -1) {
      throw StateError('Time slot not found: $timeSlotId');
    }

    final timeSlot = timeSlots[timeSlotIndex];
    if (timeSlot.isFullyBooked) {
      throw StateError('Time slot is fully booked');
    }

    if (!timeSlot.isActive) {
      throw StateError('Time slot is not active');
    }

    final updatedTimeSlots = [...timeSlots];
    updatedTimeSlots[timeSlotIndex] = timeSlot.bookAppointment(appointmentId);

    return copyWith(timeSlots: updatedTimeSlots);
  }

  /// Cancels an appointment in a specific time slot
  /// Throws exceptions if cancellation is not possible
  AppointmentSlot cancelAppointment(String timeSlotId, String appointmentId) {
    final timeSlotIndex = timeSlots.indexWhere((ts) => ts.id == timeSlotId);
    if (timeSlotIndex == -1) {
      throw StateError('Time slot not found: $timeSlotId');
    }

    final timeSlot = timeSlots[timeSlotIndex];
    if (!timeSlot.appointmentIds.contains(appointmentId)) {
      throw StateError('Appointment not found in time slot');
    }

    final updatedTimeSlots = [...timeSlots];
    updatedTimeSlots[timeSlotIndex] = timeSlot.cancelAppointment(appointmentId);

    return copyWith(timeSlots: updatedTimeSlots);
  }

  /// Checks if a specific appointment exists in any time slot
  bool hasAppointment(String appointmentId) {
    return timeSlots.any((slot) => slot.appointmentIds.contains(appointmentId));
  }

  /// Finds the time slot containing a specific appointment
  TimeSlot? findTimeSlotByAppointmentId(String appointmentId) {
    return timeSlots.firstWhere(
      (slot) => slot.appointmentIds.contains(appointmentId),
      orElse: () => throw StateError('Appointment not found in any time slot'),
    );
  }

  /// Returns true if the slot can accept new bookings
  bool get canAcceptBookings {
    return isActive && !isFullyBooked && !date.isBefore(DateTime.now());
  }

  /// Returns the number of available spots across all time slots
  int get availableSpots {
    return timeSlots.fold(
      0,
      (sum, slot) => sum + (slot.maxPatients - slot.bookedPatients),
    );
  }
}
