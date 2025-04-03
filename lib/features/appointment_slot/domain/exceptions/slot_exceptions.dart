class SlotException implements Exception {
  final String message;
  const SlotException(this.message);

  @override
  String toString() => message;
}

class SlotOverlapException extends SlotException {
  SlotOverlapException(String doctorId, DateTime date)
      : super('A slot for doctor $doctorId already exists at ${date.toString()}');
}

class InvalidSlotException extends SlotException {
  InvalidSlotException(super.message);
}