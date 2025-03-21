enum PatientGender { male, female }
enum PatientStatus { active, inactive }

class Patient {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final PatientGender gender;
  final DateTime? dateOfBirth;
  final DateTime registeredAt;
  final PatientStatus status;
  final String? notes;
  // New field for Firebase optimization - storing appointment IDs
  final List<String> appointmentIds;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.gender = PatientGender.male,
    this.dateOfBirth,
    required this.registeredAt,
    this.status = PatientStatus.active,
    this.notes,
    this.appointmentIds = const [],
  });

  // Add appointment tracking method
  Patient addAppointment(String appointmentId) {
    final updatedAppointmentIds = List<String>.from(appointmentIds);
    if (!updatedAppointmentIds.contains(appointmentId)) {
      updatedAppointmentIds.add(appointmentId);
    }
    return copyWith(appointmentIds: updatedAppointmentIds);
  }

  // Remove appointment tracking method
  Patient removeAppointment(String appointmentId) {
    final updatedAppointmentIds = List<String>.from(appointmentIds)..remove(appointmentId);
    return copyWith(appointmentIds: updatedAppointmentIds);
  }

  // Enhanced copyWith
  Patient copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    PatientGender? gender,
    DateTime? dateOfBirth,
    DateTime? registeredAt,
    PatientStatus? status,
    String? notes,
    List<String>? appointmentIds,
  }) {
    return Patient(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      appointmentIds: appointmentIds ?? this.appointmentIds,
    );
  }
  
  // Firebase-friendly conversion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gender': gender.toString().split('.').last,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'registeredAt': registeredAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'notes': notes,
      'appointmentIds': appointmentIds,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      gender: map['gender'] == 'female' ? PatientGender.female : PatientGender.male,
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.parse(map['dateOfBirth']) : null,
      registeredAt: DateTime.parse(map['registeredAt']),
      status: map['status'] == 'inactive' ? PatientStatus.inactive : PatientStatus.active,
      notes: map['notes'],
      appointmentIds: List<String>.from(map['appointmentIds'] ?? []),
    );
  }
}