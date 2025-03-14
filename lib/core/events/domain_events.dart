// lib/core/events/domain_events.dart
import '../../../features/doctor/domain/entities/doctor.dart';
import '../../../features/patient/domain/entities/patient.dart';
import '../../../features/appointment_slot/domain/entities/appointment_slot.dart';
import '../../../features/appointment/domain/entities/appointment.dart';

import 'app_event.dart';

// Doctor-related events
class DoctorCreatedEvent implements AppEvent {
  final Doctor doctor;
  
  DoctorCreatedEvent(this.doctor);
  
  @override
  String get eventType => 'DoctorCreatedEvent';
}

class DoctorUpdatedEvent implements AppEvent {
  final Doctor doctor;
  
  DoctorUpdatedEvent(this.doctor);
  
  @override
  String get eventType => 'DoctorUpdatedEvent';
}

class DoctorDeletedEvent implements AppEvent {
  final String doctorId;
  
  DoctorDeletedEvent(this.doctorId);
  
  @override
  String get eventType => 'DoctorDeletedEvent';
}

class DoctorAvailabilityChangedEvent implements AppEvent {
  final Doctor doctor;
  
  DoctorAvailabilityChangedEvent(this.doctor);
  
  @override
  String get eventType => 'DoctorAvailabilityChangedEvent';
}

// Patient-related events
class PatientCreatedEvent implements AppEvent {
  final Patient patient;
  
  PatientCreatedEvent(this.patient);
  
  @override
  String get eventType => 'PatientCreatedEvent';
}

class PatientUpdatedEvent implements AppEvent {
  final Patient patient;
  
  PatientUpdatedEvent(this.patient);
  
  @override
  String get eventType => 'PatientUpdatedEvent';
}

class PatientDeletedEvent implements AppEvent {
  final String patientId;
  
  PatientDeletedEvent(this.patientId);
  
  @override
  String get eventType => 'PatientDeletedEvent';
}

// AppointmentSlot-related events
class SlotCreatedEvent implements AppEvent {
  final AppointmentSlot slot;
  
  SlotCreatedEvent(this.slot);
  
  @override
  String get eventType => 'SlotCreatedEvent';
}

class SlotUpdatedEvent implements AppEvent {
  final AppointmentSlot slot;
  
  SlotUpdatedEvent(this.slot);
  
  @override
  String get eventType => 'SlotUpdatedEvent';
}

class SlotDeletedEvent implements AppEvent {
  final String slotId;
  
  SlotDeletedEvent(this.slotId);
  
  @override
  String get eventType => 'SlotDeletedEvent';
}

class SlotBookedEvent implements AppEvent {
  final AppointmentSlot slot;
  final String appointmentId;
  
  SlotBookedEvent(this.slot, this.appointmentId);
  
  @override
  String get eventType => 'SlotBookedEvent';
}

class SlotCancelledEvent implements AppEvent {
  final AppointmentSlot slot;
  final String appointmentId;
  
  SlotCancelledEvent(this.slot, this.appointmentId);
  
  @override
  String get eventType => 'SlotCancelledEvent';
}

// Appointment-related events
class AppointmentCreatedEvent implements AppEvent {
  final Appointment appointment;
  
  AppointmentCreatedEvent(this.appointment);
  
  @override
  String get eventType => 'AppointmentCreatedEvent';
}

class AppointmentUpdatedEvent implements AppEvent {
  final Appointment appointment;
  final Appointment oldAppointment;
  
  AppointmentUpdatedEvent(this.appointment, this.oldAppointment);
  
  @override
  String get eventType => 'AppointmentUpdatedEvent';
}

class AppointmentCancelledEvent implements AppEvent {
  final String appointmentId;
  
  AppointmentCancelledEvent(this.appointmentId);
  
  @override
  String get eventType => 'AppointmentCancelledEvent';
}

class AppointmentCompletedEvent implements AppEvent {
  final Appointment appointment;
  
  AppointmentCompletedEvent(this.appointment);
  
  @override
  String get eventType => 'AppointmentCompletedEvent';
}