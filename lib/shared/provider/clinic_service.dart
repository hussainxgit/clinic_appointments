import 'package:clinic_appointments/features/doctor_availability/controller/doctor_availability_provdier.dart';
import 'package:clinic_appointments/features/doctor_availability/models/doctor_availability.dart';

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
  final DoctorAvailabilityProvider doctorAvailabilityProvider;

  ClinicService({
    required this.appointmentProvider,
    required this.patientProvider,
    required this.doctorProvider,
    required this.doctorAvailabilityProvider,
  });

  // Add a new appointment and update the patient if necessary
  void addAppointment(Appointment appointment) {
    // Check if the patient already exists
    final existingPatient = patientProvider.patients.firstWhere(
      (patient) => patient.id == appointment.patient.id,
      orElse: () => appointment.patient,
    );

    if (existingPatient.id != appointment.patient.id) {
      patientProvider.addPatient(appointment.patient);
    }

    // check if the doctor is available at the selected date
    final isDoctorAvailable = doctorAvailabilityProvider.isDoctorAvailable(
      appointment.doctor.id,
      appointment.dateTime,
    );
    if (!isDoctorAvailable) {
      throw Exception('Doctor is not available at the selected time');
    }
    doctorAvailabilityProvider.bookPatient(appointment.doctorAvailabilityId);
    appointmentProvider.addAppointment(appointment);
  }

  // Update an appointment and its associated patient
  void updateAppointmentAndPatient(
      Appointment updatedAppointment, Appointment oldAppointment) {
    appointmentProvider.updateAppointment(updatedAppointment);
    patientProvider.updatePatient(updatedAppointment.patient);
    doctorAvailabilityProvider
        .cancelBooking(oldAppointment.doctorAvailabilityId);
    doctorAvailabilityProvider
        .bookPatient(updatedAppointment.doctorAvailabilityId);
  }

  // Remove an appointment
  void removeAppointment(String appointmentId, String availabilityId) {
    appointmentProvider.removeAppointment(appointmentId);
    doctorAvailabilityProvider.cancelBooking(availabilityId);
  }

  // Get all appointments for a specific patient
  List<Appointment> getAppointmentsForPatient(String patientId) {
    return appointmentProvider.appointments
        .where((appointment) => appointment.patient.id == patientId)
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
    appointmentProvider.updateAppointmentPatient(updatedPatient);
  }

  List<Doctor> getAvailableDoctors() {
    return doctorProvider.getAvailableDoctors();
  }

  List<DoctorAvailability> getAvailabitiesForDoctor(String doctorId) {
    return doctorAvailabilityProvider
        .getAvailabilitiesForDoctor(doctorId)
        .where((availability) =>
            availability.isFullyBooked == false &&
            availability.date.isAfter(DateTime.now()))
        .toList();
  }

  List<DateTime> getAvailableDatesForDoctor(String doctorId) {
    final availabilities =
        doctorAvailabilityProvider.getAvailabilitiesForDoctor(doctorId);
    return availabilities
        .where((availability) => availability.isFullyBooked == false)
        .toList()
        .map((availability) => availability.date)
        .toSet()
        .toList();
  }

  List<Patient> getPatients() {
    return patientProvider.patients;
  }

  List<Doctor> getDoctors() {
    return doctorProvider.doctors;
  }

  void createAvailability(DoctorAvailability availability) {
    doctorAvailabilityProvider.createAvailability(availability);
  }

  void updateAvailability(DoctorAvailability updatedAvailability) {
    doctorAvailabilityProvider.updateAvailability(updatedAvailability);
  }

  void removeAvailability(String availabilityId) {
    doctorAvailabilityProvider.removeAvailability(availabilityId);
  }

}
