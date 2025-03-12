// appointment_slot.dart - Enhanced model
class AppointmentSlot {
  final String id;
  final String doctorId;
  final DateTime date;
  final int maxPatients;
  final int bookedPatients;
  // New field for Firebase optimization - storing appointment IDs directly
  final List<String> appointmentIds;

  AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.maxPatients,
    this.bookedPatients = 0,
    this.appointmentIds = const [],
  });

  bool get isFullyBooked => bookedPatients >= maxPatients;

  // Book an appointment - returns updated slot with appointment added
  AppointmentSlot bookAppointment(String appointmentId) {
    if (isFullyBooked) throw Exception('Slot fully booked');

    // Add appointmentId to the tracking list
    final updatedAppointmentIds = List<String>.from(appointmentIds)
      ..add(appointmentId);

    return copyWith(
      bookedPatients: bookedPatients + 1,
      appointmentIds: updatedAppointmentIds,
    );
  }

  // Cancel an appointment - returns updated slot with appointment removed
  AppointmentSlot cancelAppointment(String appointmentId) {
    if (bookedPatients == 0) throw Exception('No bookings to cancel');
    if (!appointmentIds.contains(appointmentId)) {
      throw Exception('Appointment not found in this slot');
    }

    // Remove appointmentId from the tracking list
    final updatedAppointmentIds = List<String>.from(appointmentIds)
      ..remove(appointmentId);

    return copyWith(
      bookedPatients: bookedPatients - 1,
      appointmentIds: updatedAppointmentIds,
    );
  }

  // Helper method for creating a copy with updated fields
  AppointmentSlot copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    int? maxPatients,
    int? bookedPatients,
    List<String>? appointmentIds,
  }) {
    return AppointmentSlot(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      maxPatients: maxPatients ?? this.maxPatients,
      bookedPatients: bookedPatients ?? this.bookedPatients,
      appointmentIds: appointmentIds ?? this.appointmentIds,
    );
  }

  // Firebase-friendly conversion methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'date': date.toIso8601String(),
      'maxPatients': maxPatients,
      'bookedPatients': bookedPatients,
      'appointmentIds': appointmentIds,
    };
  }

  factory AppointmentSlot.fromMap(Map<String, dynamic> map) {
    return AppointmentSlot(
      id: map['id'],
      doctorId: map['doctorId'],
      date: DateTime.parse(map['date']),
      maxPatients: map['maxPatients'],
      bookedPatients: map['bookedPatients'],
      appointmentIds: List<String>.from(map['appointmentIds'] ?? []),
    );
  }
}
