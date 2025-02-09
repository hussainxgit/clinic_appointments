class DoctorAvailability {
  final String id; // Unique ID for the availability slot
  final String doctorId; // Foreign key to the Doctor model
  final DateTime date; // Date of availability

  final int maxPatients; // Maximum patients allowed in this slot
  int bookedPatients; // Number of patients already booked in this slot

  DoctorAvailability({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.maxPatients,
    this.bookedPatients = 0, // Default to 0 when creating a new slot
  });

  // Check if the slot is fully booked
  bool get isFullyBooked => bookedPatients >= maxPatients;

  // Book a patient in this slot
  void bookPatient() {
    if (!isFullyBooked) {
      bookedPatients++;
    } else {
      throw Exception("Slot is fully booked");
    }
  }

  // Cancel a booking in this slot
  void cancelBooking() {
    if (bookedPatients > 0) {
      bookedPatients--;
    } else {
      throw Exception("No bookings to cancel");
    }
  }
}
