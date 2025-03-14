// lib/features/appointment/domain/exceptions/appointment_exception.dart
class AppointmentException implements Exception {
  final String message;
  const AppointmentException(this.message);

  @override
  String toString() => message;
}

class DuplicateAppointmentIdException extends AppointmentException {
  DuplicateAppointmentIdException(String id)
      : super('An appointment with ID $id already exists');
}

class AppointmentNotFoundException extends AppointmentException {
  AppointmentNotFoundException(String id) : super('Appointment $id not found');
}

class InvalidAppointmentDataException extends AppointmentException {
  InvalidAppointmentDataException(String detail)
      : super('Invalid appointment data: $detail');
}

class AppointmentDateInPastException extends AppointmentException {
  AppointmentDateInPastException(DateTime date)
      : super('Appointment date $date is in the past');
}

class DuplicatePatientAppointmentException extends AppointmentException {
  DuplicatePatientAppointmentException(String patientId, DateTime date)
      : super('Patient $patientId already has an appointment on ${date.day}/${date.month}/${date.year}');
}

class SlotBookingException extends AppointmentException {
  SlotBookingException(String slotId)
      : super('Failed to book slot $slotId');
}