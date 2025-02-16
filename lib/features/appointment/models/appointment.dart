import '../../doctor/models/doctor.dart';
import '../../patient/models/patient.dart';

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

  Appointment({
    required this.id,
    required this.patientId,
    required this.dateTime,
    this.status = 'scheduled',
    this.paymentStatus = 'unpaid',
    required this.doctorId,
    required this.appointmentSlotId,
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
    };
  }

  copyWith({
    Patient? patient,
    DateTime? dateTime,
    String? status,
    String? paymentStatus,
    Doctor? doctor,
    String? appointmentSlotId,
  }) {
    return Appointment(
      id: id,
      patientId: patientId,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      doctorId: doctorId,
      appointmentSlotId: appointmentSlotId ?? this.appointmentSlotId,
    );
  }
}
