class DoctorException implements Exception {
  final String message;
  const DoctorException(this.message);

  @override
  String toString() {
    return message;
  }
}

class DuplicateDoctorIdException extends DoctorException {
  DuplicateDoctorIdException(String id)
      : super('A doctor with ID $id already exists');
}

class DuplicateDoctorException extends DoctorException {
  DuplicateDoctorException(String name)
      : super('Doctor  already exists');
}

class DoctorNotFoundException extends DoctorException {
  DoctorNotFoundException(String id) : super('Doctor $id not found');
}

class InvalidDoctorDataException extends DoctorException {
  InvalidDoctorDataException(String detail)
      : super('Invalid doctor data: $detail');
}

class InvalidDoctorIdException extends DoctorException {
  InvalidDoctorIdException(String id) : super('Invalid doctor ID: $id');
}

class InvalidDoctorNameException extends DoctorException {
  InvalidDoctorNameException(String name) : super('Invalid doctor name: $name');
}

class InvalidDoctorPhoneNumberException extends DoctorException {
  InvalidDoctorPhoneNumberException(String phoneNumber)
      : super('Invalid phone number: $phoneNumber');
}

class InvalidDoctorSpecialtyException extends DoctorException {
  InvalidDoctorSpecialtyException(String specialty)
      : super('Invalid specialty: $specialty');
}

class InvalidDoctorAvailabilityException extends DoctorException {
  InvalidDoctorAvailabilityException(bool isAvailable)
      : super('Invalid availability: $isAvailable');
}
