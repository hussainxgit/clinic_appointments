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
import '../../../core/utils/error_handler.dart';
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
  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    return ErrorHandler.guardAsync(() async {
      // Validate all entities and business rules
      final validationResult = await _validateAppointmentCreation(appointment);
      if (validationResult.isFailure) {
        throw validationResult.error;
      }

      final patient = validationResult.data['patient'];
      final slot = validationResult.data['slot'];

      // Execute the creation transaction
      final result = await _executeAppointmentCreation(
        appointment,
        patient,
        slot,
      );

      return result;
    }, 'creating appointment');
  }

  /// Updates an existing appointment
  Future<Result<Appointment>> updateAppointment(
    Appointment updatedAppointment,
  ) async {
    return ErrorHandler.guardAsync(() async {
      // Find and validate the existing appointment
      final existingAppointmentResult = await _appointmentRepository.getById(
        updatedAppointment.id,
      );

      if (existingAppointmentResult.isFailure) {
        throw existingAppointmentResult.error;
      }

      final existingAppointment = existingAppointmentResult.data;
      if (existingAppointment == null) {
        throw 'Appointment not found';
      }

      // Validate doctor
      final doctorResult = await _validateDoctor(updatedAppointment.doctorId);
      if (doctorResult.isFailure) {
        throw doctorResult.error;
      }

      // Handle slot changes
      if (existingAppointment.appointmentSlotId !=
          updatedAppointment.appointmentSlotId) {
        final slotChangeResult = await _handleSlotChange(
          existingAppointment,
          updatedAppointment,
        );
        if (slotChangeResult.isFailure) {
          throw slotChangeResult.error;
        }
      }

      // Handle patient changes
      if (existingAppointment.patientId != updatedAppointment.patientId) {
        final patientChangeResult = await _handlePatientChange(
          existingAppointment,
          updatedAppointment,
        );
        if (patientChangeResult.isFailure) {
          throw patientChangeResult.error;
        }
      }

      // Update the appointment
      final savedAppointmentResult = await _appointmentRepository.update(
        updatedAppointment,
      );

      if (savedAppointmentResult.isFailure) {
        throw savedAppointmentResult.error;
      }

      // Publish update event
      _eventBus.publish(
        AppointmentUpdatedEvent(
          savedAppointmentResult.data,
          existingAppointment,
        ),
      );

      return savedAppointmentResult.data;
    }, 'updating appointment');
  }

  /// Cancels an appointment and updates related entities
  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    return ErrorHandler.guardAsync(() async {
      // Find appointment
      final appointmentResult = await _appointmentRepository.getById(
        appointmentId,
      );

      if (appointmentResult.isFailure) {
        throw appointmentResult.error;
      }

      final appointment = appointmentResult.data;
      if (appointment == null) {
        throw 'Appointment not found';
      }

      // Update appointment status
      final cancelledAppointment = appointment.copyWith(
        status: AppointmentStatus.cancelled,
      );

      final updateResult = await _appointmentRepository.update(
        cancelledAppointment,
      );
      if (updateResult.isFailure) {
        throw updateResult.error;
      }

      // Cancel slot booking
      final cancelSlotResult = await _cancelSlotBooking(
        appointment.appointmentSlotId,
        appointmentId,
      );
      if (cancelSlotResult.isFailure) {
        // Consider whether to roll back appointment status
        throw cancelSlotResult.error;
      }

      // Remove from patient's appointments
      final removeFromPatientResult = await _removeAppointmentFromPatient(
        appointment.patientId,
        appointmentId,
      );
      if (removeFromPatientResult.isFailure) {
        // Log but don't fail the operation
        print('Warning: ${removeFromPatientResult.error}');
      }

      // Publish cancellation event
      _eventBus.publish(AppointmentCancelledEvent(appointmentId));

      return true;
    }, 'cancelling appointment');
  }

  /// Marks an appointment as completed
  Future<Result<Appointment>> completeAppointment(
    String appointmentId, {
    String? notes,
    PaymentStatus paymentStatus = PaymentStatus.paid,
  }) async {
    return ErrorHandler.guardAsync(() async {
      // Find appointment
      final appointmentResult = await _appointmentRepository.getById(
        appointmentId,
      );

      if (appointmentResult.isFailure) {
        throw appointmentResult.error;
      }

      final appointment = appointmentResult.data;
      if (appointment == null) {
        throw 'Appointment not found';
      }

      // Validate current status
      if (appointment.status == AppointmentStatus.completed) {
        throw 'Appointment is already completed';
      }

      if (appointment.status == AppointmentStatus.cancelled) {
        throw 'Cannot complete a cancelled appointment';
      }

      // Update appointment
      final completedAppointment = appointment.copyWith(
        status: AppointmentStatus.completed,
        paymentStatus: paymentStatus,
        notes: notes ?? appointment.notes,
      );

      final savedAppointmentResult = await _appointmentRepository.update(
        completedAppointment,
      );

      if (savedAppointmentResult.isFailure) {
        throw savedAppointmentResult.error;
      }

      // Publish completion event
      _eventBus.publish(AppointmentCompletedEvent(savedAppointmentResult.data));

      return savedAppointmentResult.data;
    }, 'completing appointment');
  }

  /// Fetches appointments with related patient and doctor data
  Future<Result<List<Map<String, dynamic>>>> getCombinedAppointments({
    String? patientId,
    String? doctorId,
    DateTime? date,
    String? status,
  }) async {
    return ErrorHandler.guardAsync(() async {
      Result<List<Appointment>> appointmentsResult;

      // Apply filters
      if (patientId != null) {
        appointmentsResult = await _appointmentRepository.getByPatientId(
          patientId,
        );
      } else if (doctorId != null) {
        appointmentsResult = await _appointmentRepository.getByDoctorId(
          doctorId,
        );
      } else if (date != null) {
        appointmentsResult = await _appointmentRepository.getByDate(date);
      } else if (status != null) {
        appointmentsResult = await _appointmentRepository.getByStatus(status);
      } else {
        appointmentsResult = await _appointmentRepository.getAll();
      }

      if (appointmentsResult.isFailure) {
        throw appointmentsResult.error;
      }

      // Combine with patient and doctor data
      final relatedDataResult = await _attachRelatedData(
        appointmentsResult.data,
      );

      if (relatedDataResult.isFailure) {
        throw relatedDataResult.error;
      }

      return relatedDataResult.data;
    }, 'fetching combined appointments');
  }

  // PRIVATE HELPER METHODS

  /// Validates all requirements for creating an appointment
  Future<Result<Map<String, dynamic>>> _validateAppointmentCreation(
    Appointment appointment,
  ) async {
    return ErrorHandler.guardAsync(() async {
      // 1. Basic data validation
      if (appointment.patientId.isEmpty) {
        throw 'Patient ID cannot be empty';
      }

      if (appointment.doctorId.isEmpty) {
        throw 'Doctor ID cannot be empty';
      }

      if (appointment.appointmentSlotId.isEmpty) {
        throw 'Appointment slot ID cannot be empty';
      }

      if (appointment.dateTime.isBefore(DateTime.now())) {
        throw 'Appointment cannot be scheduled in the past';
      }

      // 2. Validate patient exists and is active
      final patientResult = await _patientRepository.getById(
        appointment.patientId,
      );

      if (patientResult.isFailure) {
        throw patientResult.error;
      }

      if (patientResult.data == null) {
        throw 'Patient not found';
      }

      final patient = patientResult.data!;
      if (patient.status != PatientStatus.active) {
        throw 'Patient is not active';
      }

      // 3. Validate doctor exists and is available
      final doctorResult = await _validateDoctor(appointment.doctorId);
      if (doctorResult.isFailure) {
        throw doctorResult.error;
      }

      // 4. Validate slot
      final slotResult = await _slotRepository.getById(
        appointment.appointmentSlotId,
      );

      if (slotResult.isFailure) {
        throw slotResult.error;
      }

      if (slotResult.data == null) {
        throw 'Appointment slot not found';
      }

      final slot = slotResult.data!;
      if (slot.isFullyBooked) {
        throw 'Appointment slot is fully booked';
      }

      // 5. Validate slot belongs to selected doctor
      if (slot.doctorId != appointment.doctorId) {
        throw 'Appointment slot does not belong to the selected doctor';
      }

      // 6. Validate appointment time matches slot time
      if (!_isSameDateTime(slot.date, appointment.dateTime)) {
        throw 'Appointment time does not match slot time';
      }

      // 7. Check patient doesn't have another appointment on the same day
      final patientAppointmentsResult = await _appointmentRepository
          .getByPatientId(appointment.patientId);

      if (patientAppointmentsResult.isFailure) {
        throw patientAppointmentsResult.error;
      }

      final patientAppointments = patientAppointmentsResult.data;
      final hasConflict = patientAppointments.any(
        (a) =>
            a.status == AppointmentStatus.scheduled &&
            a.isSameDay(appointment.dateTime) &&
            a.id !=
                appointment
                    .id, // Skip checking current appointment (for updates)
      );

      if (hasConflict) {
        throw 'Patient already has an appointment on this day';
      }

      return {'patient': patient, 'slot': slot};
    }, 'validating appointment creation');
  }

  /// Execute appointment creation after validation
  /// Execute appointment creation after validation
  Future<Appointment> _executeAppointmentCreation(
    Appointment appointment,
    dynamic patient,
    dynamic slot,
  ) async {
    bool slotUpdated = false;
    bool appointmentCreated = false;
    String? appointmentId;

    try {
      // 1. Create appointment first (so we have the ID)
      final savedAppointmentResult = await _appointmentRepository.create(
        appointment,
      );

      if (savedAppointmentResult.isFailure) {
        throw savedAppointmentResult.error;
      }

      final savedAppointment = savedAppointmentResult.data;
      appointmentCreated = true;
      appointmentId = savedAppointment.id;

      // 2. Book the slot with the actual appointment ID
      final updatedSlot = slot.bookAppointment(savedAppointment.id);
      final slotUpdateResult = await _slotRepository.update(updatedSlot);

      if (slotUpdateResult.isFailure) {
        throw slotUpdateResult.error;
      }

      slotUpdated = true;

      // 3. Update patient's appointment references
      // Make sure we have a fresh List<String>
      final List<String> currentAppointments = List<String>.from(
        patient.appointmentIds,
      );

      final updatedPatient = patient.copyWith(
        appointmentIds: [...currentAppointments, savedAppointment.id],
      );

      final patientUpdateResult = await _patientRepository.update(
        updatedPatient,
      );

      if (patientUpdateResult.isFailure) {
        throw patientUpdateResult.error;
      }

      // Publish event for successful creation
      _eventBus.publish(AppointmentCreatedEvent(savedAppointment));

      return savedAppointment;
    } catch (e) {
      // Rollback operations if needed
      await _rollbackOperations(
        slotUpdated: slotUpdated,
        slotId: slot.id,
        appointmentId: appointmentId,
        appointmentCreated: appointmentCreated,
      );
      rethrow;
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
      await ErrorHandler.guardAsync(() async {
        final slotResult = await _slotRepository.getById(slotId);
        if (slotResult.isFailure) {
          throw slotResult.error;
        }

        if (slotResult.data != null) {
          // Use the fixed cancelAppointment that won't throw if not found
          final updatedSlot = slotResult.data!.cancelAppointment(appointmentId);
          final updateResult = await _slotRepository.update(updatedSlot);
          if (updateResult.isFailure) {
            throw updateResult.error;
          }
        }
      }, 'restoring slot during rollback').catchError((error) {
        print('Rollback warning: $error');
      });
    }

    // Then try to delete the appointment
    if (appointmentCreated && appointmentId != null) {
      await ErrorHandler.guardAsync(() async {
        final deleteResult = await _appointmentRepository.delete(
          appointmentId,
        );
        if (deleteResult.isFailure) {
          throw deleteResult.error;
        }
      }, 'deleting appointment during rollback').catchError((error) {
        print('Rollback warning: $error');
      });
    }
  }

  /// Validate that doctor exists and is available
  Future<Result<void>> _validateDoctor(String doctorId) async {
    return ErrorHandler.guardAsync(() async {
      final doctorResult = await _doctorRepository.getById(doctorId);

      if (doctorResult.isFailure) {
        throw doctorResult.error;
      }

      if (doctorResult.data == null) {
        throw 'Doctor not found';
      }

      if (!doctorResult.data!.isAvailable) {
        throw 'Doctor is not available';
      }
    }, 'validating doctor');
  }

  /// Handle changes to the slot when updating an appointment
  Future<Result<void>> _handleSlotChange(
    Appointment existingAppointment,
    Appointment updatedAppointment,
  ) async {
    return ErrorHandler.guardAsync(() async {
      // Cancel old slot
      final oldSlotResult = await _slotRepository.getById(
        existingAppointment.appointmentSlotId,
      );

      if (oldSlotResult.isFailure) {
        throw oldSlotResult.error;
      }

      final cancelledSlot = oldSlotResult.data!.cancelAppointment(
        existingAppointment.id,
      );
      final updateOldSlotResult = await _slotRepository.update(cancelledSlot);

      if (updateOldSlotResult.isFailure) {
        throw updateOldSlotResult.error;
      }

      // Book new slot
      final newSlotResult = await _slotRepository.getById(
        updatedAppointment.appointmentSlotId,
      );

      if (newSlotResult.isFailure) {
        throw newSlotResult.error;
      }

      if (newSlotResult.data!.isFullyBooked) {
        throw 'New appointment slot is fully booked';
      }

      final bookedSlot = newSlotResult.data!.bookAppointment(
        updatedAppointment.id,
      );
      final bookSlotResult = await _slotRepository.update(bookedSlot);

      if (bookSlotResult.isFailure) {
        throw bookSlotResult.error;
      }
    }, 'updating appointment slots');
  }

  /// Handle changes to the patient when updating an appointment
  Future<Result<void>> _handlePatientChange(
    Appointment existingAppointment,
    Appointment updatedAppointment,
  ) async {
    return ErrorHandler.guardAsync(() async {
      // Remove from old patient
      final removeResult = await _removeAppointmentFromPatient(
        existingAppointment.patientId,
        existingAppointment.id,
      );

      if (removeResult.isFailure) {
        throw removeResult.error;
      }

      // Add to new patient
      final newPatientResult = await _patientRepository.getById(
        updatedAppointment.patientId,
      );

      if (newPatientResult.isFailure) {
        throw newPatientResult.error;
      }

      if (newPatientResult.data == null) {
        throw 'New patient not found';
      }

      final updatedNewPatient = newPatientResult.data!.copyWith(
        appointmentIds: [
          ...newPatientResult.data!.appointmentIds,
          updatedAppointment.id,
        ],
      );

      final updateResult = await _patientRepository.update(updatedNewPatient);
      if (updateResult.isFailure) {
        throw updateResult.error;
      }
    }, 'updating patient references');
  }

  /// Cancel a booking in a slot
  Future<Result<void>> _cancelSlotBooking(
    String slotId,
    String appointmentId,
  ) async {
    return ErrorHandler.guardAsync(() async {
      final slotResult = await _slotRepository.getById(slotId);

      if (slotResult.isFailure) {
        throw slotResult.error;
      }

      if (slotResult.data == null) {
        throw 'Slot not found';
      }

      final updatedSlot = slotResult.data!.cancelAppointment(appointmentId);
      final updateResult = await _slotRepository.update(updatedSlot);

      if (updateResult.isFailure) {
        throw updateResult.error;
      }
    }, 'cancelling slot booking');
  }

  /// Remove an appointment reference from a patient
  Future<Result<void>> _removeAppointmentFromPatient(
    String patientId,
    String appointmentId,
  ) async {
    return ErrorHandler.guardAsync(() async {
      final patientResult = await _patientRepository.getById(patientId);

      if (patientResult.isFailure) {
        throw patientResult.error;
      }

      if (patientResult.data == null) {
        throw 'Patient not found';
      }

      // Create a new list to avoid modifying the original
      List<String> updatedAppointmentIds = List.from(
        patientResult.data!.appointmentIds,
      );
      updatedAppointmentIds.remove(appointmentId);

      final updatedPatient = patientResult.data!.copyWith(
        appointmentIds: updatedAppointmentIds,
      );

      final updateResult = await _patientRepository.update(updatedPatient);

      if (updateResult.isFailure) {
        throw updateResult.error;
      }
    }, 'removing appointment from patient');
  }

  /// Attach patient and doctor data to a list of appointments
  Future<Result<List<Map<String, dynamic>>>> _attachRelatedData(
    List<Appointment> appointments,
  ) async {
    return ErrorHandler.guardAsync(() async {
      List<Map<String, dynamic>> result = [];

      for (final appointment in appointments) {
        final patientResult = await _patientRepository.getById(
          appointment.patientId,
        );
        final doctorResult = await _doctorRepository.getById(
          appointment.doctorId,
        );

        // Log errors but don't fail the entire operation
        if (patientResult.isFailure) {
          print(
            'Warning: Failed to load patient data - ${patientResult.error}',
          );
        }

        if (doctorResult.isFailure) {
          print('Warning: Failed to load doctor data - ${doctorResult.error}');
        }

        result.add({
          'appointment': appointment,
          'patient': patientResult.isSuccess ? patientResult.data : null,
          'doctor': doctorResult.isSuccess ? doctorResult.data : null,
        });
      }

      return result;
    }, 'attaching related data to appointments');
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
