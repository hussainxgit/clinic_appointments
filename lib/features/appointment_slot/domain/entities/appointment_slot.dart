// lib/features/appointment_slot/domain/entities/appointment_slot.dart
class AppointmentSlot {
  final String id;
  final String doctorId;
  final DateTime date;
  final int maxPatients;
  final int bookedPatients;
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

  // Create a copy with updated fields
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

  // Book an appointment
  AppointmentSlot bookAppointment(String appointmentId) {
    if (isFullyBooked) {
      throw Exception('Slot fully booked');
    }

    final updatedAppointmentIds = List<String>.from(appointmentIds)
      ..add(appointmentId);

    return copyWith(
      bookedPatients: bookedPatients + 1,
      appointmentIds: updatedAppointmentIds,
    );
  }

  // Cancel an appointment
  AppointmentSlot cancelAppointment(String appointmentId) {
    if (bookedPatients == 0) {
      throw Exception('No bookings to cancel');
    }
    if (!appointmentIds.contains(appointmentId)) {
      throw Exception('Appointment not found in this slot');
    }

    final updatedAppointmentIds = List<String>.from(appointmentIds)
      ..remove(appointmentId);

    return copyWith(
      bookedPatients: bookedPatients - 1,
      appointmentIds: updatedAppointmentIds,
    );
  }

  // Firebase-friendly conversion
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
      id: map['id'] ?? '',
      doctorId: map['doctorId'] ?? '',
      date: DateTime.parse(map['date']),
      maxPatients: map['maxPatients'] ?? 0,
      bookedPatients: map['bookedPatients'] ?? 0,
      appointmentIds: List<String>.from(map['appointmentIds'] ?? []),
    );
  }
}