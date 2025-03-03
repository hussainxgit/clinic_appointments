import 'package:clinic_appointments/features/appointment_slot/controller/appointment_slot_provdier.dart';
import 'package:clinic_appointments/features/appointment_slot/models/appointment_slot.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import '../../features/appointment/controller/appointment_provider.dart';
import '../../features/appointment/models/appointment.dart';
import '../../features/doctor/controller/doctor_provider.dart';
import '../../features/doctor/models/doctor.dart';
import '../../features/patient/controller/patient_provider.dart';
import '../../features/patient/models/patient.dart';
import '../utilities/globals.dart';

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

// Helper method unchanged
  void _showMessage(String message, {bool isError = false}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> createAppointment(Appointment appointment) async {
    try {
      patientProvider.patients.firstWhere(
          (p) => p.id == appointment.patientId); // Validate patient exists
      appointmentProvider.addAppointment(appointment); // Validate appointment
      appointmentSlotProvider
          .bookSlot(appointment.appointmentSlotId); // Validate slot
      _showMessage('Appointment created successfully');
    } catch (e) {
      _showMessage('Failed to create appointment: $e', isError: true);
    }
  }

  void updateAppointmentAndPatient(
      Appointment updatedAppointment, Appointment oldAppointment) {
    try {
      appointmentProvider.updateAppointment(updatedAppointment);
      appointmentSlotProvider.cancelSlot(oldAppointment.appointmentSlotId);
      appointmentSlotProvider.bookSlot(updatedAppointment.appointmentSlotId);
      _showMessage('Appointment updated successfully');
    } catch (e) {
      _showMessage('Failed to update appointment: $e', isError: true);
    }
  }

  void removeAppointment(String appointmentId, String availabilityId) {
    try {
      appointmentProvider.removeAppointment(appointmentId);
      appointmentSlotProvider.cancelSlot(availabilityId);
      _showMessage('Appointment removed successfully');
    } catch (e) {
      _showMessage('Failed to remove appointment: $e', isError: true);
    }
  }

  List<Map<String, dynamic>> getCombinedAppointments({String? patientId}) {
    return appointmentProvider.appointments
        .where((appointment) =>
            patientId == null ||
            appointment.patientId ==
                patientId) // Filter by patientId if provided
        .map((appointment) {
      // Find patient details
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == appointment.patientId,
        orElse: () => Patient(
          id: 'unknown',
          name: 'Unknown Patient',
          phone: '',
          registeredAt: DateTime.now(),
        ),
      );

      // Find doctor details
      final doctor = doctorProvider.doctors.firstWhere(
        (d) =>
            d.id ==
            appointment.doctorId, // Fixed: Use doctorId instead of patientId
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown Doctor',
          specialty: '',
          phoneNumber: '',
          email: '',
          isAvailable: false,
        ),
      );

      // Return combined data
      return {
        'appointment': appointment,
        'patient': patient,
        'doctor': doctor,
      };
    }).toList();
  }

  List<Map<String, dynamic>> getCombinedAppointmentsByDate(DateTime date) {
    return appointmentProvider.appointments
        .where((appointment) =>
            appointment.dateTime.isSameDay(date))
        .map((appointment) {
      // Find patient details
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == appointment.patientId,
        orElse: () => Patient(
          id: 'unknown',
          name: 'Unknown Patient',
          phone: '',
          registeredAt: DateTime.now(),
        ),
      );

      // Find doctor details
      final doctor = doctorProvider.doctors.firstWhere(
        (d) =>
            d.id ==
            appointment.doctorId, // Fixed: Use doctorId instead of patientId
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown Doctor',
          specialty: '',
          phoneNumber: '',
          email: '',
          isAvailable: false,
        ),
      );

      // Return combined data
      return {
        'appointment': appointment,
        'patient': patient,
        'doctor': doctor,
      };
    }).toList();
  }

  List<Appointment> getAppointmentsForPatient(String patientId) {
    return appointmentProvider.appointments
        .where((appointment) => appointment.patientId == patientId)
        .toList();
  }

  int getTotalPatients() => patientProvider.patients.length;
  int getTotalAppointments() => appointmentProvider.appointments.length;

  List<Appointment> getTodaysAppointments() {
    final today = DateTime.now().toLocal().removeTime();
    return appointmentProvider.appointments
        .where((appointment) =>
            appointment.dateTime.toLocal().removeTime().isAtSameMomentAs(today))
        .toList();
  }

  List<Appointment> getCancelledAppointments() {
    return appointmentProvider.appointments
        .where((appointment) => appointment.status.toLowerCase() == 'cancelled')
        .toList();
  }

  void addPatient(Patient patient) {
    try {
      patientProvider.addPatient(patient);
      _showMessage('Patient added successfully');
    } catch (e) {
      _showMessage('Failed to add patient: $e', isError: true);
      rethrow;
    }
  }

  void removePatient(String patientId) {
    try {
      patientProvider.removePatient(patientId);
      _showMessage('Patient removed successfully');
    } catch (e) {
      _showMessage('Failed to remove patient: $e', isError: true);
      rethrow;
    }
  }

  void updatePatient(Patient updatedPatient) {
    try {
      patientProvider.updatePatient(updatedPatient);
      _showMessage('Patient updated successfully');
    } catch (e) {
      _showMessage('Failed to update patient: $e', isError: true);
      rethrow;
    }
  }

  List<Doctor> getAvailableDoctorsWithSlots() {
    final availableDoctors = doctorProvider.getAvailableDoctors();
    return availableDoctors.where((doctor) {
      return appointmentSlotProvider.getSlots(doctorId: doctor.id).any((slot) =>
          !slot.isFullyBooked && slot.date.isSameDayOrAfter(DateTime.now()));
    }).toList();
  }

  List<AppointmentSlot> getAppointmentSlots(
      {String? doctorId, DateTime? date}) {
    final today = DateTime.now();
    return appointmentSlotProvider
        .getSlots(doctorId: doctorId)
        .where(
            (slot) => !slot.isFullyBooked && slot.date.isSameDayOrAfter(today))
        .toList();
  }

  List<AppointmentSlot> getSlotsByDate({required DateTime date}) =>
      appointmentSlotProvider.getSlots(date: date);

  List<Map<String, dynamic>> getCombinedSlotsWithDoctors({DateTime? date}) {
    // Get all slots from the provider
    final slots = appointmentSlotProvider.getSlots();

    // Filter slots by date if provided
    final filteredSlots = date != null
        ? slots.where((slot) {
            final slotDate = slot.date;
            return slotDate.year == date.year &&
                slotDate.month == date.month &&
                slotDate.day == date.day;
          }).toList()
        : slots;

    // Map filtered slots to include their corresponding doctors
    return filteredSlots.map((slot) {
      final doctor = doctorProvider.doctors.firstWhere(
        (d) => d.id == slot.doctorId,
        orElse: () => Doctor(
          id: 'unknown',
          name: 'Unknown Doctor',
          specialty: '',
          phoneNumber: '',
          email: '',
          isAvailable: false,
        ),
      );
      return {'slot': slot, 'doctor': doctor};
    }).toList();
  }

  List<AppointmentSlot> getAllAppointmentSlots({String? doctorId}) =>
      appointmentSlotProvider.getSlots();

  List<Patient> getPatients() => patientProvider.patients;
  List<Doctor> getDoctors() => doctorProvider.doctors;

  void createAppointmentSlot(AppointmentSlot appointmentSlot) {
    try {
      appointmentSlotProvider.addSlot(appointmentSlot);
      _showMessage('Appointment slot created successfully');
    } catch (e) {
      _showMessage('Failed to create slot: $e', isError: true);
    }
  }

  void updateAppointmentSlot(AppointmentSlot updatedAppointmentSlot) {
    try {
      appointmentSlotProvider.updateSlot(
          updatedAppointmentSlot.id, (existingSlot) => updatedAppointmentSlot);
      _showMessage('Appointment slot updated successfully');
    } catch (e) {
      _showMessage('Failed to update appointment slot: $e', isError: true);
      rethrow;
    }
  }

  void removeAppointmentSlot(String appointmentSlotId) {
    try {
      appointmentSlotProvider.removeSlot(appointmentSlotId);
      _showMessage('Appointment slot removed successfully');
    } catch (e) {
      _showMessage('$e', isError: true);
    }
  }

  void addDoctor(Doctor doctor) {
    try {
      doctorProvider.addDoctor(doctor);
      _showMessage('Doctor added successfully');
    } catch (e) {
      _showMessage('$e', isError: true);
    }
  }

  List<Map<String, dynamic>> searchAppointmentsByPhone(String phoneQuery) {
    final matchingPatients = patientProvider.searchPatientsByPhone(phoneQuery);
    final patientIds = matchingPatients.map((p) => p.id).toList();
    final appointments =
        appointmentProvider.getAppointmentsByPatientIds(patientIds);
    return appointments.map((appointment) {
      final patient = matchingPatients.firstWhere(
        (p) => p.id == appointment.patientId,
        orElse: () => Patient(
            id: '', name: 'Unknown', phone: '', registeredAt: DateTime.now()),
      );
      return {'appointment': appointment, 'patient': patient};
    }).toList();
  }

  Future<void> createAppointmentFromForm({
    required String phone,
    required String name,
    String? notes,
    required String doctorId,
    required DateTime dateTime,
    required String appointmentSlotId,
    String status = 'scheduled',
    String paymentStatus = 'unpaid',
  }) async {
    try {
      final patient = patientProvider.patients.firstWhere(
        (p) => p.phone == phone.trim(),
        orElse: () => Patient(
          id: DateTime.now().toString(),
          name: name.trim(),
          phone: phone.trim(),
          registeredAt: DateTime.now(),
          notes: notes?.trim(),
        ),
      );

      if (!patientProvider.patients.contains(patient)) {
        addPatient(patient);
      }

      final appointment = Appointment(
        id: DateTime.now().toString(),
        patientId: patient.id,
        dateTime: dateTime,
        status: status,
        paymentStatus: paymentStatus,
        appointmentSlotId: appointmentSlotId,
        doctorId: doctorId,
      );

      await createAppointment(
          appointment); // Will throw if patient has another appointment
    } catch (e) {
      _showMessage('Failed to create appointment: $e', isError: true);
    }
  }

  void deleteDoctor(String doctorId) {
    try {
      doctorProvider.removeDoctor(doctorId);
      appointmentSlotProvider.removeSlotsByDoctorId(doctorId);
      _showMessage('Doctor removed successfully');
    } catch (e) {
      _showMessage('Failed to remove doctor: $e', isError: true);
    }
  }

  List<AppointmentSlot> getUpcomingSlots() {
    return appointmentSlotProvider.getSlots().where((slot) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final slotDate = DateTime(slot.date.year, slot.date.month, slot.date.day);
      return !slot.isFullyBooked && slotDate.isSameDayOrAfter(today);
    }).toList();
  }

  List<Patient> searchPatientByQuery(String searchQuery) {
    return patientProvider.patients.where((patient) {
      final query = searchQuery.toLowerCase();
      return patient.name.toLowerCase().contains(query) ||
          patient.id.toLowerCase().contains(query) ||
          patient.phone.toLowerCase().contains(query);
    }).toList();
  }

  List<Doctor> searchDoctorByQuery(String searchQuery) {
    return doctorProvider.doctors.where((doctor) {
      final query = searchQuery.toLowerCase();
      return doctor.name.toLowerCase().contains(query) ||
          doctor.id.toLowerCase().contains(query) ||
          doctor.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> searchAppointmentsByQuery(String searchQuery) {
    final matchingPatients = patientProvider.searchPatientsByQuery(searchQuery);
    final patientIds = matchingPatients.map((p) => p.id).toList();
    final appointments =
        appointmentProvider.getAppointmentsByPatientIds(patientIds);
    return appointments.map((appointment) {
      final patient = matchingPatients.firstWhere(
        (p) => p.id == appointment.patientId,
        orElse: () => Patient(
            id: '', name: 'Unknown', phone: '', registeredAt: DateTime.now()),
      );
      return {'appointment': appointment, 'patient': patient};
    }).toList();
  }
}
