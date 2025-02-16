import 'package:clinic_appointments/features/appointment_slot/controller/appointment_slot_provdier.dart';
import 'package:clinic_appointments/features/appointment_slot/models/appointment_slot.dart';

import '../../features/appointment/controller/appointment_provider.dart';
import '../../features/appointment/models/appointment.dart';
import '../../features/doctor/controller/doctor_provider.dart';
import '../../features/doctor/models/doctor.dart';
import '../../features/patient/controller/patient_provider.dart';
import '../../features/patient/models/patient.dart';

class ClinicService {
  final AppointmentProvider appointmentProvider;
  final PatientProvider patientProvider;
  final DoctorProvider doctorProvider;
  final AppointmentSlotProvider appointmentSlotProvider;

  ClinicService({
    required this.appointmentProvider,
    required this.patientProvider,
    required this.doctorProvider,
    required this.appointmentSlotProvider,
  });

  // Add a new appointment and update the patient if necessary
  Future<void> createAppointment(Appointment appointment) async {
    try {
      // Validate patient exists
      patientProvider.patients.firstWhere((p) => p.id == appointment.patientId);

      // Validate slot availability
      final slot = appointmentSlotProvider.slots
          .firstWhere((s) => s.id == appointment.appointmentSlotId);

      if (slot.isFullyBooked) {
        throw Exception('Slot is fully booked');
      }

      // Transactional update
      appointmentSlotProvider.bookSlot(slot.id);
      appointmentProvider.addAppointment(appointment);
    } on StateError catch (_) {
      throw Exception('Invalid patient or slot');
    }
  }

  // Update an appointment and its associated patient
  void updateAppointmentAndPatient(
      Appointment updatedAppointment, Appointment oldAppointment) {
    appointmentProvider.updateAppointment(updatedAppointment);
    appointmentSlotProvider.cancelBooking(oldAppointment.appointmentSlotId);
    appointmentSlotProvider.bookPatient(updatedAppointment.appointmentSlotId);
  }

  // Remove an appointment
  void removeAppointment(String appointmentId, String availabilityId) {
    appointmentProvider.removeAppointment(appointmentId);
    appointmentSlotProvider.cancelBooking(availabilityId);
  }

  // Combine appointments with patient details
  List<Map<String, dynamic>> getCombinedAppointments() {
    return appointmentProvider.appointments.map((appointment) {
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == appointment.patientId,
        orElse: () => Patient(
          id: 'unknown',
          name: 'Unknown Patient',
          phone: '',
          registeredAt: DateTime.now(),
        ),
      );
      return {
        'appointment': appointment,
        'patient': patient,
      };
    }).toList();
  }

  // Get all appointments for a specific patient
  List<Appointment> getAppointmentsForPatient(String patientId) {
    return appointmentProvider.appointments
        .where((appointment) => appointment.patientId == patientId)
        .toList();
  }

  // Get the total number of patients
  int getTotalPatients() {
    return patientProvider.patients.length;
  }

  // Get the total number of appointments
  int getTotalAppointments() {
    return appointmentProvider.appointments.length;
  }

  // Get today's appointments
  List<Appointment> getTodaysAppointments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return appointmentProvider.appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      return appointmentDate == today;
    }).toList();
  }

  // Get cancelled appointments
  List<Appointment> getCancelledAppointments() {
    return appointmentProvider.appointments
        .where((appointment) => appointment.status.toLowerCase() == 'cancelled')
        .toList();
  }

  void addPatient(Patient patient) {
    patientProvider.addPatient(patient);
  }

  void removePatient(String patientId) {
    patientProvider.removePatient(patientId);
  }

  void updatePatient(Patient updatedPatient) {
    // Update the patient in PatientProvider
    patientProvider.updatePatient(updatedPatient);

    // ✅ Ensure all related appointments reflect this update
    appointmentProvider.updatePatientInAppointments(updatedPatient);
  }

  List<Doctor> getAvailableDoctors() {
    return doctorProvider.getAvailableDoctors();
  }

  List<AppointmentSlot> getAppointmentSlotsForDoctor(String doctorId) {
    return appointmentSlotProvider
        .getAppointmentSlotsForDoctor(doctorId)
        .where((availability) =>
            availability.isFullyBooked == false &&
            availability.date.isAfter(DateTime.now()))
        .toList();
  }

  List<AppointmentSlot> getAllAppointmentSlotsForDoctor(String doctorId) {
    final appointmentSlots =
        appointmentSlotProvider.getAppointmentSlotsForDoctor(doctorId);
    return appointmentSlots;
  }

  List<Patient> getPatients() {
    return patientProvider.patients;
  }

  List<Doctor> getDoctors() {
    return doctorProvider.doctors;
  }

  void createAppointmentSlot(AppointmentSlot availability) {
    appointmentSlotProvider.createAppointmentSlot(availability);
  }

  void updateAppointmentSlot(AppointmentSlot updatedAppointmentSlot) {
    appointmentSlotProvider.updateAppointmentSlot(updatedAppointmentSlot);
  }

  void removeAppointmentSlot(String appointmentSlotId) {
    appointmentSlotProvider.removeAppointmentSlot(appointmentSlotId);
  }
}
