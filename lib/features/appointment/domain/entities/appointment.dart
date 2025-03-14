// lib/features/appointment/domain/entities/appointment.dart
enum AppointmentStatus { scheduled, completed, cancelled }
enum PaymentStatus { paid, unpaid }

class Appointment {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final String status;
  final String paymentStatus;
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

  Appointment copyWith({
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'paymentStatus': paymentStatus,
      'doctorId': doctorId,
      'appointmentSlotId': appointmentSlotId,
      'notes': notes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] ?? '',
      patientId: map['patientId'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'scheduled',
      paymentStatus: map['paymentStatus'] ?? 'unpaid',
      doctorId: map['doctorId'] ?? '',
      appointmentSlotId: map['appointmentSlotId'] ?? '',
      notes: map['notes'],
    );
  }
  
  bool isSameDay(DateTime date) {
    return dateTime.year == date.year && 
           dateTime.month == date.month && 
           dateTime.day == date.day;
  }
}