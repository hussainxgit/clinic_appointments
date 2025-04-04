import '../../../../core/exceptions/exceptions.dart';

class TimeSlotException extends AppException {
  const TimeSlotException(super.message);
}

class TimeSlotNotFoundException extends TimeSlotException {
  TimeSlotNotFoundException(String id) : super('Time slot $id not found');
}

class TimeSlotFullyBookedException extends TimeSlotException {
  TimeSlotFullyBookedException(String id)
      : super('Time slot with ID $id is fully booked');
}

class TimeSlotNotBookedException extends TimeSlotException {
  TimeSlotNotBookedException(String id)
      : super('Time slot with ID $id has no bookings to cancel');
}

class InvalidTimeSlotException extends TimeSlotException {
  InvalidTimeSlotException(String detail)
      : super('Invalid time slot data: $detail');
}

class TimeSlotOverlapException extends TimeSlotException {
  TimeSlotOverlapException(String slotId, String startTime)
      : super('Time slot $slotId overlaps with existing slot at $startTime');
}

class TimeSlotInPastException extends TimeSlotException {
  TimeSlotInPastException(String startTime)
      : super('Time slot start time $startTime is in the past');
}

class DuplicateTimeSlotIdException extends TimeSlotException {
  DuplicateTimeSlotIdException(String id)
      : super('A time slot with ID $id already exists');
}

class TimeSlotDurationException extends TimeSlotException {
  TimeSlotDurationException(String detail)
      : super('Invalid time slot duration: $detail');
}

class TimeSlotCapacityException extends TimeSlotException {
  TimeSlotCapacityException(String detail)
      : super('Invalid time slot capacity: $detail');
}

class TimeSlotBookingException extends TimeSlotException {
  TimeSlotBookingException(String id, String detail)
      : super('Failed to book time slot $id: $detail');
}

class TimeSlotCancellationException extends TimeSlotException {
  TimeSlotCancellationException(String id, String detail)
      : super('Failed to cancel time slot $id: $detail');
}

class TimeSlotNotActiveException extends TimeSlotException {
  TimeSlotNotActiveException(String id)
      : super('Time slot $id is not active');
}

class TimeSlotAlreadyBookedException extends TimeSlotException {
  TimeSlotAlreadyBookedException(String id, String appointmentId)
      : super('Appointment $appointmentId is already booked in time slot $id');
}