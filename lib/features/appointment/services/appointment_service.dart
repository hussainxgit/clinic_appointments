// lib/features/appointment/services/appointment_service.dart
import 'package:clinic_appointments/core/di/core_providers.dart';
import 'package:clinic_appointments/features/appointment/data/appointment_repository.dart';
import 'package:clinic_appointments/features/appointment_slot/data/appointment_slot_repository.dart';
import 'package:clinic_appointments/features/doctor/data/doctor_repository.dart';
import 'package:clinic_appointments/features/patient/data/patient_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/events/event_bus.dart';
import '../../../../core/events/domain_events.dart';
import '../../appointment_slot/data/appointment_slot_providers.dart';
import '../../patient/data/patient_providers.dart';
import '../../doctor/data/doctor_provider.dart';
import '../../patient/domain/entities/patient.dart';
import '../data/appointment_providers.dart';
import '../domain/entities/appointment.dart';

part 'appointment_service.g.dart';

/// Provider for the AppointmentService
@riverpod
AppointmentService appointmentService(Ref ref) {
  return AppointmentService(
    appointmentRepository: ref.watch(appointmentRepositoryProvider),
    patientRepository: ref.watch(patientRepositoryProvider),
    doctorRepository: ref.watch(doctorRepositoryProvider),
    slotRepository: ref.watch(appointmentSlotRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
}

/// Service for handling complex appointment operations
///
/// This service coordinates operations that affect multiple entities
/// (patients, doctors, slots) and handles business logic validation.
class AppointmentService {
  final AppointmentRepository _appointmentRepository;
  final PatientRepository _patientRepository;
  final DoctorRepository _doctorRepository;
  final AppointmentSlotRepository _slotRepository;
  final EventBus _eventBus;

  AppointmentService({
    required AppointmentRepository appointmentRepository,
    required PatientRepository patientRepository,
    required DoctorRepository doctorRepository,
    required AppointmentSlotRepository slotRepository,
    required EventBus eventBus,
  }) : _appointmentRepository = appointmentRepository,
       _patientRepository = patientRepository,
       _doctorRepository = doctorRepository,
       _slotRepository = slotRepository,
       _eventBus = eventBus;

  /// Creates a new appointment with all necessary validations
  ///
  /// This operation affects multiple entities:
  /// - Validates patient, doctor and slot
  /// - Checks for conflicting appointments
  /// - Updates the slot booking
  /// - Creates the appointment
  /// - Updates the patient's appointment list
  /// - Publishes an event
  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    try {
      // Validate all entities and business rules
      final validationResult = await _validateAppointmentCreation(appointment);
      if (validationResult.isFailure) {
        return Result.failure(validationResult.error);
      }

      final patient = validationResult.data['patient'];
      final slot = validationResult.data['slot'];

      // Execute the creation transaction
      return await _executeAppointmentCreation(appointment, patient, slot);
    } catch (e) {
      return Result.failure('Failed to create appointment: ${e.toString()}');
    }
  }

  /// Updates an existing appointment
  ///
  /// Handles:
  /// - Slot changes (canceling old slot, booking new slot)
  /// - Patient changes (removing from old patient, adding to new)
  /// - Status changes
  Future<Result<Appointment>> updateAppointment(
    Appointment updatedAppointment,
  ) async {
    try {
      // Find and validate the existing appointment
      final existingAppointment = await _appointmentRepository.getById(
        updatedAppointment.id,
      );
      if (existingAppointment == null) {
        return Result.failure('Appointment not found');
      }

      // Validate doctor
      final doctorResult = await _validateDoctor(updatedAppointment.doctorId);
      if (doctorResult.isFailure) {
        return Result.failure(doctorResult.error);
      }

      // Handle slot changes
      if (existingAppointment.appointmentSlotId !=
          updatedAppointment.appointmentSlotId) {
        final slotChangeResult = await _handleSlotChange(
          existingAppointment,
          updatedAppointment,
        );
        if (slotChangeResult.isFailure) {
          return Result.failure(slotChangeResult.error);
        }
      }

      // Handle patient changes
      if (existingAppointment.patientId != updatedAppointment.patientId) {
        final patientChangeResult = await _handlePatientChange(
          existingAppointment,
          updatedAppointment,
        );
        if (patientChangeResult.isFailure) {
          return Result.failure(patientChangeResult.error);
        }
      }

      // Update the appointment
      final savedAppointment = await _appointmentRepository.update(
        updatedAppointment,
      );

      // Publish update event
      _eventBus.publish(
        AppointmentUpdatedEvent(savedAppointment, existingAppointment),
      );

      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure('Failed to update appointment: ${e.toString()}');
    }
  }

  /// Cancels an appointment and updates related entities
  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    try {
      // Find appointment
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }

      // Update appointment status
      final cancelledAppointment = appointment.copyWith(
        status: AppointmentStatus.cancelled,
      );
      await _appointmentRepository.update(cancelledAppointment);

      // Cancel slot booking
      await _cancelSlotBooking(appointment.appointmentSlotId, appointmentId);

      // Remove from patient's appointments
      await _removeAppointmentFromPatient(appointment.patientId, appointmentId);

      // Publish cancellation event
      _eventBus.publish(AppointmentCancelledEvent(appointmentId));

      return Result.success(true);
    } catch (e) {
      return Result.failure('Failed to cancel appointment: ${e.toString()}');
    }
  }

  /// Marks an appointment as completed
  Future<Result<Appointment>> completeAppointment(
    String appointmentId, {
    String? notes,
    PaymentStatus paymentStatus = PaymentStatus.paid,
  }) async {
    try {
      // Find appointment
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }

      // Validate current status
      if (appointment.status == AppointmentStatus.completed) {
        return Result.failure('Appointment is already completed');
      }

      if (appointment.status == AppointmentStatus.cancelled) {
        return Result.failure('Cannot complete a cancelled appointment');
      }

      // Update appointment
      final completedAppointment = appointment.copyWith(
        status: AppointmentStatus.completed,
        paymentStatus: paymentStatus,
        notes: notes ?? appointment.notes,
      );

      final savedAppointment = await _appointmentRepository.update(
        completedAppointment,
      );

      // Publish completion event
      _eventBus.publish(AppointmentCompletedEvent(savedAppointment));

      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure('Failed to complete appointment: ${e.toString()}');
    }
  }

  /// Fetches appointments with related patient and doctor data
  Future<Result<List<Map<String, dynamic>>>> getCombinedAppointments({
    String? patientId,
    String? doctorId,
    DateTime? date,
    String? status,
  }) async {
    try {
      List<Appointment> appointments;

      // Apply filters
      if (patientId != null) {
        appointments = await _appointmentRepository.getByPatientId(patientId);
      } else if (doctorId != null) {
        appointments = await _appointmentRepository.getByDoctorId(doctorId);
      } else if (date != null) {
        appointments = await _appointmentRepository.getByDate(date);
      } else if (status != null) {
        appointments = await _appointmentRepository.getByStatus(status);
      } else {
        appointments = await _appointmentRepository.getAll();
      }

      // Combine with patient and doctor data
      final result = await _attachRelatedData(appointments);
      return Result.success(result);
    } catch (e) {
      return Result.failure('Failed to get appointments: ${e.toString()}');
    }
  }

  // PRIVATE HELPER METHODS

  /// Validates all requirements for creating an appointment
  Future<Result<Map<String, dynamic>>> _validateAppointmentCreation(
    Appointment appointment,
  ) async {
    // 1. Basic data validation
    if (appointment.patientId.isEmpty) {
      return Result.failure('Patient ID cannot be empty');
    }

    if (appointment.doctorId.isEmpty) {
      return Result.failure('Doctor ID cannot be empty');
    }

    if (appointment.appointmentSlotId.isEmpty) {
      return Result.failure('Appointment slot ID cannot be empty');
    }

    if (appointment.dateTime.isBefore(DateTime.now())) {
      return Result.failure('Appointment cannot be scheduled in the past');
    }

    // 2. Validate patient exists and is active
    final patient = await _patientRepository.getById(appointment.patientId);
    if (patient == null) {
      return Result.failure('Patient not found');
    }

    if (patient.status != PatientStatus.active) {
      return Result.failure('Patient is not active');
    }

    // 3. Validate doctor exists and is available
    final doctorResult = await _validateDoctor(appointment.doctorId);
    if (doctorResult.isFailure) {
      return Result.failure(doctorResult.error);
    }

    // 4. Validate slot
    final slot = await _slotRepository.getById(appointment.appointmentSlotId);
    if (slot == null) {
      return Result.failure('Appointment slot not found');
    }

    if (slot.isFullyBooked) {
      return Result.failure('Appointment slot is fully booked');
    }

    // 5. Validate slot belongs to selected doctor
    if (slot.doctorId != appointment.doctorId) {
      return Result.failure(
        'Appointment slot does not belong to the selected doctor',
      );
    }

    // 6. Validate appointment time matches slot time
    if (!_isSameDateTime(slot.date, appointment.dateTime)) {
      return Result.failure('Appointment time does not match slot time');
    }

    // 7. Check patient doesn't have another appointment on the same day
    final patientAppointments = await _appointmentRepository.getByPatientId(
      appointment.patientId,
    );
    final hasConflict = patientAppointments.any(
      (a) =>
          a.status == AppointmentStatus.scheduled &&
          a.isSameDay(appointment.dateTime) &&
          a.id !=
              appointment.id, // Skip checking current appointment (for updates)
    );

    if (hasConflict) {
      return Result.failure('Patient already has an appointment on this day');
    }

    return Result.success({'patient': patient, 'slot': slot});
  }

  /// Execute appointment creation after validation
  Future<Result<Appointment>> _executeAppointmentCreation(
    Appointment appointment,
    dynamic patient,
    dynamic slot,
  ) async {
    try {
      // Track which operations have succeeded for potential rollback
      bool slotUpdated = false;
      bool appointmentCreated = false;
      String? appointmentId;

      // 1. Create appointment first (so we have the ID)
      try {
        final savedAppointment = await _appointmentRepository.create(
          appointment,
        );
        appointmentCreated = true;
        appointmentId = savedAppointment.id;

        // 2. Book the slot with the actual appointment ID
        try {
          final updatedSlot = slot.bookAppointment(savedAppointment.id);
          await _slotRepository.update(updatedSlot);
          slotUpdated = true;
        } catch (e) {
          // Rollback the appointment creation
          if (appointmentCreated) {
            try {
              await _appointmentRepository.delete(savedAppointment.id);
            } catch (rollbackErr) {
              print(
                'Rollback error - could not delete appointment: $rollbackErr',
              );
            }
          }
          return Result.failure('Error booking slot: ${e.toString()}');
        }

        // 3. Update patient's appointment references
        try {
          // Make sure we have a fresh List<String>
          final List<String> currentAppointments = List<String>.from(
            patient.appointmentIds,
          );

          final updatedPatient = patient.copyWith(
            appointmentIds: [...currentAppointments, savedAppointment.id],
          );
          await _patientRepository.update(updatedPatient);

          return Result.success(savedAppointment);
        } catch (e) {
          // Rollback slot and appointment
          await _rollbackOperations(
            slotUpdated: slotUpdated,
            slotId: slot.id,
            appointmentId: appointmentId,
            appointmentCreated: appointmentCreated,
          );
          return Result.failure('Error updating patient: ${e.toString()}');
        }
      } catch (e) {
        return Result.failure('Error creating appointment: ${e.toString()}');
      }
    } catch (e) {
      return Result.failure('Error in appointment creation: ${e.toString()}');
    }
  }

  // rollback helper method
  Future<void> _rollbackOperations({
    required bool slotUpdated,
    required String slotId,
    String? appointmentId,
    required bool appointmentCreated,
  }) async {
    // First try to cancel the slot booking
    if (slotUpdated && appointmentId != null) {
      try {
        final slot = await _slotRepository.getById(slotId);
        if (slot != null) {
          // Use the fixed cancelAppointment that won't throw if not found
          final updatedSlot = slot.cancelAppointment(appointmentId);
          await _slotRepository.update(updatedSlot);
        }
      } catch (e) {
        print('Rollback error - could not restore slot: $e');
      }
    }

    // Then try to delete the appointment
    if (appointmentCreated && appointmentId != null) {
      try {
        await _appointmentRepository.delete(appointmentId);
      } catch (e) {
        print('Rollback error - could not delete appointment: $e');
      }
    }
  } 

  /// Validate that doctor exists and is available
  Future<Result<void>> _validateDoctor(String doctorId) async {
    final doctor = await _doctorRepository.getById(doctorId);
    if (doctor == null) {
      return Result.failure('Doctor not found');
    }

    if (!doctor.isAvailable) {
      return Result.failure('Doctor is not available');
    }

    return Result.success(null);
  }

  /// Handle changes to the slot when updating an appointment
  Future<Result<void>> _handleSlotChange(
    Appointment existingAppointment,
    Appointment updatedAppointment,
  ) async {
    try {
      // Cancel old slot
      final oldSlot = await _slotRepository.getById(
        existingAppointment.appointmentSlotId,
      );
      if (oldSlot != null) {
        final cancelledSlot = oldSlot.cancelAppointment(existingAppointment.id);
        await _slotRepository.update(cancelledSlot);
      }

      // Book new slot
      final newSlot = await _slotRepository.getById(
        updatedAppointment.appointmentSlotId,
      );
      if (newSlot == null) {
        return Result.failure('New appointment slot not found');
      }

      if (newSlot.isFullyBooked) {
        return Result.failure('New appointment slot is fully booked');
      }

      final bookedSlot = newSlot.bookAppointment(updatedAppointment.id);
      await _slotRepository.update(bookedSlot);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        'Failed to update appointment slots: ${e.toString()}',
      );
    }
  }

  /// Handle changes to the patient when updating an appointment
  Future<Result<void>> _handlePatientChange(
    Appointment existingAppointment,
    Appointment updatedAppointment,
  ) async {
    try {
      // Remove from old patient
      await _removeAppointmentFromPatient(
        existingAppointment.patientId,
        existingAppointment.id,
      );

      // Add to new patient
      final newPatient = await _patientRepository.getById(
        updatedAppointment.patientId,
      );
      if (newPatient == null) {
        return Result.failure('New patient not found');
      }

      final updatedNewPatient = newPatient.copyWith(
        appointmentIds: [...newPatient.appointmentIds, updatedAppointment.id],
      );
      await _patientRepository.update(updatedNewPatient);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        'Failed to update patient references: ${e.toString()}',
      );
    }
  }

  /// Cancel a booking in a slot
  Future<void> _cancelSlotBooking(String slotId, String appointmentId) async {
    final slot = await _slotRepository.getById(slotId);
    if (slot != null) {
      final updatedSlot = slot.cancelAppointment(appointmentId);
      await _slotRepository.update(updatedSlot);
    }
  }

  /// Remove an appointment reference from a patient
  Future<void> _removeAppointmentFromPatient(
    String patientId,
    String appointmentId,
  ) async {
    final patient = await _patientRepository.getById(patientId);
    if (patient != null) {
      final updatedPatient = patient.copyWith(
        appointmentIds: patient.appointmentIds..remove(appointmentId),
      );
      await _patientRepository.update(updatedPatient);
    }
  }

  /// Attach patient and doctor data to a list of appointments
  Future<List<Map<String, dynamic>>> _attachRelatedData(
    List<Appointment> appointments,
  ) async {
    List<Map<String, dynamic>> result = [];

    for (final appointment in appointments) {
      final patient = await _patientRepository.getById(appointment.patientId);
      final doctor = await _doctorRepository.getById(appointment.doctorId);

      result.add({
        'appointment': appointment,
        'patient': patient,
        'doctor': doctor,
      });
    }

    return result;
  }
}

// Helper method to check if two DateTimes represent the same time
// (ignoring seconds and milliseconds)
bool _isSameDateTime(DateTime a, DateTime b) {
  return a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour &&
      a.minute == b.minute;
}
