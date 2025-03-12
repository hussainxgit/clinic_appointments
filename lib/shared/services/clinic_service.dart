import 'package:clinic_appointments/features/appointment_slot/controller/appointment_slot_provdier.dart';
import 'package:clinic_appointments/features/appointment_slot/models/appointment_slot.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import '../../features/appointment/controller/appointment_provider.dart';
import '../../features/appointment/models/appointment.dart';
import '../../features/doctor/controller/doctor_provider.dart';
import '../../features/doctor/models/doctor.dart';
import '../../features/patient/controller/patient_provider.dart';
import '../../features/patient/models/patient.dart';
import 'notification_service.dart';
import 'service_result.dart';

class ClinicService {
  final AppointmentProvider appointmentProvider;
  final PatientProvider patientProvider;
  final DoctorProvider doctorProvider;
  final AppointmentSlotProvider appointmentSlotProvider;
  final NotificationService notificationService;

  ClinicService({
    required this.appointmentProvider,
    required this.patientProvider,
    required this.doctorProvider,
    required this.appointmentSlotProvider,
    required this.notificationService,
  });

  int getTotalPatients() => patientProvider.patients.length;
  int getTotalAppointments() => appointmentProvider.appointments.length;
  List<Patient> getPatients() => patientProvider.patients;
  List<Doctor> getDoctors() => doctorProvider.doctors;

  Future<ServiceResult<List<Appointment>>> getPatientAppointments(
      String patientId) async {
    try {
      // 1. Get patient to access appointment IDs directly
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == patientId,
        orElse: () => throw Exception("Patient not found"),
      );

      // 2. Efficiently query only needed appointments
      final appointments = appointmentProvider.appointments
          .where((a) => patient.appointmentIds.contains(a.id))
          .toList();

      return ServiceResult.success(appointments);
    } catch (e) {
      notificationService.showError('Failed to get patient appointments: $e');
      return ServiceResult.failure(e.toString());
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
        .where((appointment) => appointment.dateTime.isSameDay(date))
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

  List<AppointmentSlot> getUpcomingSlots() {
    return appointmentSlotProvider.getSlots().where((slot) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final slotDate = DateTime(slot.date.year, slot.date.month, slot.date.day);
      return !slot.isFullyBooked && slotDate.isSameDayOrAfter(today);
    }).toList();
  }

  Future<ServiceResult<Appointment>> createAppointment(
      Appointment appointment) async {
    try {
      // 1. Validate patient exists
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == appointment.patientId,
        orElse: () => throw Exception("Patient not found"),
      );

      // 2. Book the slot first
      try {
        // Get the slot and book it with appointment tracking
        appointmentSlotProvider.updateSlot(
          appointment.appointmentSlotId,
          (slot) => slot.bookAppointment(appointment.id),
        );
      } catch (e) {
        throw Exception("Failed to book slot: $e");
      }

      // 3. Add appointment
      try {
        appointmentProvider.addAppointment(appointment);
      } catch (e) {
        // Rollback slot booking if appointment creation fails
        appointmentSlotProvider.updateSlot(
          appointment.appointmentSlotId,
          (slot) => slot.cancelAppointment(appointment.id),
        );
        throw Exception("Failed to create appointment: $e");
      }

      // 4. Update patient with appointment reference
      try {
        final updatedPatient = patient.addAppointment(appointment.id);
        patientProvider.updatePatient(updatedPatient);
      } catch (e) {
        // Log warning but don't fail the operation
        print(
            "Warning: Failed to update patient with appointment reference: $e");
      }

      notificationService.showSuccess('Appointment created successfully');
      return ServiceResult.success(appointment);
    } catch (e) {
      notificationService.showError('Failed to create appointment: $e');
      return ServiceResult.failure(e.toString());
    }
  }

  ServiceResult<void> updateAppointmentAndPatient(
      Appointment updatedAppointment, Appointment oldAppointment) {
    try {
      appointmentProvider.updateAppointment(updatedAppointment);
      appointmentSlotProvider.cancelSlot(
          oldAppointment.appointmentSlotId, oldAppointment.id);
      appointmentSlotProvider.bookSlot(
          updatedAppointment.appointmentSlotId, updatedAppointment.id);
      notificationService.showSuccess('Appointment updated successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to update appointment: $e');
      return ServiceResult.failure('Failed to update appointment: $e');
    }
  }

  Future<ServiceResult<void>> removeAppointment(String appointmentId) async {
    try {
      // 1. Find the appointment
      final appointment = appointmentProvider.appointments.firstWhere(
        (a) => a.id == appointmentId,
        orElse: () => throw Exception("Appointment not found"),
      );

      // 2. Cancel the slot booking
      try {
        appointmentSlotProvider.updateSlot(
          appointment.appointmentSlotId,
          (slot) => slot.cancelAppointment(appointmentId),
        );
      } catch (e) {
        throw Exception("Failed to cancel slot booking: $e");
      }

      // 3. Update patient's appointment references
      try {
        final patient = patientProvider.patients.firstWhere(
          (p) => p.id == appointment.patientId,
        );
        final updatedPatient = patient.removeAppointment(appointmentId);
        patientProvider.updatePatient(updatedPatient);
      } catch (e) {
        // Log warning but don't fail the operation
        print("Warning: Failed to update patient appointment reference: $e");
      }

      // 4. Remove the appointment
      appointmentProvider.removeAppointment(appointmentId);

      notificationService.showSuccess('Appointment removed successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to remove appointment: $e');
      return ServiceResult.failure(e.toString());
    }
  }

  Future<ServiceResult<Patient>> addPatient(Patient patient) async {
    try {
      patientProvider.addPatient(patient);
      notificationService.showSuccess('Patient added successfully');
      return ServiceResult.success(patient);
    } catch (e) {
      notificationService.showError('Failed to add patient: $e');
      return ServiceResult.failure(e.toString());
    }
  }

  ServiceResult<void> removePatient(String patientId) {
    try {
      patientProvider.removePatient(patientId);
      appointmentProvider.removePatientAppointments(patientId);

      notificationService.showSuccess('Patient removed successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to remove patient: $e');
      return ServiceResult.failure('Failed to remove patient: $e');
    }
  }

  ServiceResult<void> updatePatient(Patient updatedPatient) {
    try {
      patientProvider.updatePatient(updatedPatient);
      notificationService.showSuccess('Patient updated successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to update patient: $e');
      return ServiceResult.failure('Failed to update patient: $e');
    }
  }

  ServiceResult<void> createAppointmentSlot(AppointmentSlot appointmentSlot) {
    try {
      appointmentSlotProvider.addSlot(appointmentSlot);
      notificationService.showSuccess('Appointment slot created successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to create slot: $e');
      return ServiceResult.failure('Failed to create slot: $e');
    }
  }

  ServiceResult<void> updateAppointmentSlot(
      AppointmentSlot updatedAppointmentSlot) {
    try {
      appointmentSlotProvider.updateSlot(
          updatedAppointmentSlot.id, (existingSlot) => updatedAppointmentSlot);
      notificationService.showSuccess('Appointment slot updated successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to update appointment slot: $e');
      return ServiceResult.failure('Failed to update appointment slot: $e');
    }
  }

  ServiceResult<void> removeAppointmentSlot(String appointmentSlotId) {
    try {
      appointmentSlotProvider.removeSlot(appointmentSlotId);
      notificationService.showSuccess('Appointment slot removed successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to remove appointment slot: $e');
      return ServiceResult.failure('Failed to remove appointment slot: $e');
    }
  }

  ServiceResult<void> addDoctor(Doctor doctor) {
    try {
      doctorProvider.addDoctor(doctor);
      notificationService.showSuccess('Doctor added successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to add doctor: $e');
      return ServiceResult.failure('Failed to add doctor: $e');
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

  Future<ServiceResult<void>> createAppointmentFromForm({
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

      final result = await createAppointment(appointment);
      if (result.isSuccess) {
        return ServiceResult.success(null);
      } else {
        return ServiceResult.failure(result.errorMessage);
      }
    } catch (e) {
      notificationService.showError('Failed to create appointment: $e');
      return ServiceResult.failure('Failed to create appointment: $e');
    }
  }

  ServiceResult<void> deleteDoctor(String doctorId) {
    try {
      doctorProvider.removeDoctor(doctorId);
      appointmentSlotProvider.removeSlotsByDoctorId(doctorId);
      notificationService.showSuccess('Doctor removed successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to remove doctor: $e');
      return ServiceResult.failure('Failed to remove doctor: $e');
    }
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

  ServiceResult<void> suspendPatient(String patientId) {
    try {
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == patientId,
        orElse: () => throw Exception('Patient not found'),
      );
      final updatedPatient = patient.copyWith(status: PatientStatus.inactive);
      updatePatient(updatedPatient);
      notificationService.showSuccess('Patient suspended successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to suspend patient: $e');
      return ServiceResult.failure('Failed to suspend patient: $e');
    }
  }

  ServiceResult<void> activatePatient(String patientId) {
    try {
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == patientId,
        orElse: () => throw Exception('Patient not found'),
      );
      final updatedPatient = patient.copyWith(status: PatientStatus.active);
      updatePatient(updatedPatient);
      notificationService.showSuccess('Patient activated successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to activate patient: $e');
      return ServiceResult.failure('Failed to activate patient: $e');
    }
  }

  Future<ServiceResult<void>> removePatientWithCascade(String patientId) async {
    try {
      // 1. Find the patient to get appointment IDs
      final patient = patientProvider.patients.firstWhere(
        (p) => p.id == patientId,
        orElse: () => throw Exception("Patient not found"),
      );

      // 2. Get all appointments for this patient
      final patientAppointmentIds = patient.appointmentIds;
      final appointments = appointmentProvider.appointments
          .where((a) => patientAppointmentIds.contains(a.id))
          .toList();

      // 3. Process each appointment - cancel slot bookings
      for (final appointment in appointments) {
        try {
          // Update the slot by canceling the appointment
          appointmentSlotProvider.updateSlot(
            appointment.appointmentSlotId,
            (slot) => slot.cancelAppointment(appointment.id),
          );
        } catch (e) {
          // Log error but continue with other appointments
          print(
              "Warning: Failed to cancel slot for appointment ${appointment.id}: $e");
        }
      }

      // 4. Remove all appointments for this patient
      for (final appointmentId in patientAppointmentIds) {
        appointmentProvider.removeAppointment(appointmentId);
      }

      // 5. Finally remove the patient
      patientProvider.removePatient(patientId);

      notificationService
          .showSuccess('Patient and related appointments removed successfully');
      return ServiceResult.success(null);
    } catch (e) {
      notificationService.showError('Failed to remove patient: $e');
      return ServiceResult.failure(e.toString());
    }
  }

  Future<ServiceResult<Appointment>> updateAppointment(
      Appointment updatedAppointment) async {
    try {
      // Find the old appointment to get slot information
      final oldAppointment = appointmentProvider.appointments.firstWhere(
        (a) => a.id == updatedAppointment.id,
        orElse: () => throw Exception("Appointment not found"),
      );

      // Check if the appointment slot changed
      bool slotChanged = oldAppointment.appointmentSlotId !=
          updatedAppointment.appointmentSlotId;

      // If slot changed, we need to update both slots
      if (slotChanged) {
        try {
          // Book the new slot first
          appointmentSlotProvider.bookSlot(
              updatedAppointment.appointmentSlotId, updatedAppointment.id);

          // Cancel the old slot
          appointmentSlotProvider.cancelSlot(
              oldAppointment.appointmentSlotId, updatedAppointment.id);
        } catch (e) {
          // If either operation fails, ensure we don't leave things in a bad state
          throw Exception("Failed to update appointment slots: $e");
        }
      }

      // Update the appointment in the provider
      appointmentProvider.updateAppointment(updatedAppointment);

      // Update patient's appointment information if needed
      if (oldAppointment.patientId != updatedAppointment.patientId) {
        try {
          // Remove from old patient
          final oldPatient = patientProvider.patients
              .firstWhere((p) => p.id == oldAppointment.patientId);
          final updatedOldPatient =
              oldPatient.removeAppointment(updatedAppointment.id);
          patientProvider.updatePatient(updatedOldPatient);

          // Add to new patient
          final newPatient = patientProvider.patients
              .firstWhere((p) => p.id == updatedAppointment.patientId);
          final updatedNewPatient =
              newPatient.addAppointment(updatedAppointment.id);
          patientProvider.updatePatient(updatedNewPatient);
        } catch (e) {
          // Log but don't fail the operation
          print("Warning: Failed to update patient appointment references: $e");
        }
      }

      notificationService.showSuccess('Appointment updated successfully');
      return ServiceResult.success(updatedAppointment);
    } catch (e) {
      notificationService.showError('Failed to update appointment: $e');
      return ServiceResult.failure(e.toString());
    }
  }
}
