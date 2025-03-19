// Update in lib/features/appointment/domain/entities/appointment.dart
enum AppointmentStatus { scheduled, completed, cancelled }
enum PaymentStatus { paid, unpaid }

class Appointment {
  final String id;
  final String patientId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final PaymentStatus paymentStatus;
  final String doctorId;
  final String appointmentSlotId;
  final String? notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.dateTime,
    this.status = AppointmentStatus.scheduled,
    this.paymentStatus = PaymentStatus.unpaid,
    required this.doctorId,
    required this.appointmentSlotId,
    this.notes,
  });

  Appointment copyWith({
    String? patientId,
    DateTime? dateTime,
    AppointmentStatus? status,
    PaymentStatus? paymentStatus,
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
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
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
      status: _parseStatus(map['status'] ?? 'scheduled'),
      paymentStatus: _parsePaymentStatus(map['paymentStatus'] ?? 'unpaid'),
      doctorId: map['doctorId'] ?? '',
      appointmentSlotId: map['appointmentSlotId'] ?? '',
      notes: map['notes'],
    );
  }
  
  static AppointmentStatus _parseStatus(String status) {
    switch (status) {
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.scheduled;
    }
  }
  
  static PaymentStatus _parsePaymentStatus(String status) {
    return status == 'paid' ? PaymentStatus.paid : PaymentStatus.unpaid;
  }
  
  

  bool isSameDay(DateTime date) {
    return dateTime.year == date.year && 
           dateTime.month == date.month && 
           dateTime.day == date.day;
  }
}