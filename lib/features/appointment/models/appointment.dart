enum AppointmentStatus { scheduled, completed, cancelled }

enum PaymentStatus { paid, unpaid }

class Appointment {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String paymentStatus; // 'paid', 'unpaid'
  final String doctorId;
  final String appointmentSlotId;
  final String? notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.dateTime,
    this.status = 'scheduled',
    this.paymentStatus = 'unpaid',
    required this.doctorId,
    required this.appointmentSlotId,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patientId: json['patientId'],
      dateTime: DateTime.parse(json['dateTime']),
      doctorId: json['doctorId'],
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      appointmentSlotId: json['appointmentSlotId'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'doctorId': doctorId,
      'status': status,
      'paymentStatus': paymentStatus,
      'appointmentSlotId': appointmentSlotId,
      'notes': notes,
    };
  }

  copyWith({
    String? patientId,
    DateTime? dateTime,
    String? status,
    String? paymentStatus,
    String? doctorId,
    String? appointmentSlotId,
    String? notes,
  }) {
    return Appointment(
      id: id,
      patientId: patientId ?? this.patientId,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      doctorId: doctorId ?? this.doctorId,
      appointmentSlotId: appointmentSlotId ?? this.appointmentSlotId,
      notes: notes ?? this.notes,
    );
  }
}
