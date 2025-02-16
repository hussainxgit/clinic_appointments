class AppointmentSlot {
  final String id;
  final String doctorId;
  final DateTime date;
  final int maxPatients;
  final int bookedPatients;

  AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.maxPatients,
    this.bookedPatients = 0,
  });

  bool get isFullyBooked => bookedPatients >= maxPatients;

  // Immutable methods
  AppointmentSlot bookPatient() {
    if (isFullyBooked) throw Exception('Slot fully booked');
    return copyWith(bookedPatients: bookedPatients + 1);
  }

  AppointmentSlot cancelBooking() {
    if (bookedPatients == 0) throw Exception('No bookings to cancel');
    return copyWith(bookedPatients: bookedPatients - 1);
  }

  // Helper method for creating a copy with updated fields
  AppointmentSlot copyWith({
    String? id,
    String? doctorId,
    DateTime? date,
    int? maxPatients,
    int? bookedPatients,
  }) {
    return AppointmentSlot(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      date: date ?? this.date,
      maxPatients: maxPatients ?? this.maxPatients,
      bookedPatients: bookedPatients ?? this.bookedPatients,
    );
  }
}
