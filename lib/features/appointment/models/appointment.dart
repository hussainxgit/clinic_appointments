import '../../doctor/models/doctor.dart';
import '../../patient/models/patient.dart';

enum AppointmentStatus { scheduled, completed, cancelled }

enum PaymentStatus { paid, unpaid }

class Appointment {
  final String id;
  Patient patient;
  final DateTime dateTime;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String paymentStatus; // 'paid', 'unpaid'
  Doctor doctor;
  final String doctorAvailabilityId;

  Appointment({
    required this.id,
    required this.patient,
    required this.dateTime,
    this.status = 'scheduled',
    this.paymentStatus = 'unpaid',
    required this.doctor,
    required this.doctorAvailabilityId,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patient: Patient.fromJson(json['patient']),
      dateTime: DateTime.parse(json['dateTime']),
      doctor: Doctor.fromJson(json['doctor']),
      status: json['status'],
      paymentStatus: json['paymentStatus'],
      doctorAvailabilityId: json['doctorAvailabilityId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient': patient.toJson(),
      'dateTime': dateTime.toIso8601String(),
      'doctor': doctor.toJson(),
      'status': status,
      'paymentStatus': paymentStatus,
      'doctorAvailabilityId': doctorAvailabilityId,
    };
  }
}
