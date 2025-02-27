class SlotException implements Exception {
  final String message;
  const SlotException(this.message);

  @override
  String toString() {
    return message;
  }
}

class DuplicateSlotIdException extends SlotException {
  DuplicateSlotIdException(String id)
      : super('A slot with ID $id already exists');
}

class SameDaySlotException extends SlotException {
  SameDaySlotException(String doctorId, DateTime date)
      : super(
            'A slot for doctor $doctorId already exists on ${date.day}/${date.month}/${date.year}');
}

class SlotNotFoundException extends SlotException {
  SlotNotFoundException(String id) : super('Slot $id not found');
}

class SlotHasBookingsException extends SlotException {
  SlotHasBookingsException(String id)
      : super('Cannot remove slot with ID: $id, because it has bookings');
}

class SlotFullyBookedException extends SlotException {
  SlotFullyBookedException(String id)
      : super('Slot with ID $id is fully booked');
}

class SlotNotBookedException extends SlotException {
  SlotNotBookedException(String id)
      : super('Slot with ID $id has no bookings to cancel');
}

class InvalidSlotDataException extends SlotException {
  InvalidSlotDataException(String detail) : super('Invalid slot data: $detail');
}

class SlotDateInPastException extends SlotException {
  SlotDateInPastException(DateTime date)
      : super('Slot date $date is in the past');
}
