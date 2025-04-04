// lib/features/appointment/services/appointment_service.dart

import 'package:clinic_appointments/core/di/core_providers.dart';
import 'package:clinic_appointments/core/utils/boali_date_extenstions.dart';
import 'package:clinic_appointments/core/utils/error_handler.dart';
import 'package:clinic_appointments/core/utils/result.dart';
import 'package:clinic_appointments/features/appointment/data/appointment_repository.dart';
import 'package:clinic_appointments/features/appointment_slot/data/appointment_slot_repository.dart';
import 'package:clinic_appointments/features/doctor/data/doctor_repository.dart';
import 'package:clinic_appointments/features/patient/data/patient_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/events/event_bus.dart';
import '../../../core/events/domain_events.dart';
import '../../appointment_slot/data/appointment_slot_providers.dart';
import '../../appointment_slot/domain/entities/appointment_slot.dart';
import '../../appointment_slot/domain/entities/time_slot.dart';
import '../../doctor/data/doctor_provider.dart';
import '../../patient/data/patient_providers.dart';
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

  /// Creates a new appointment
  Future<Result<Appointment>> createAppointment({
    required String patientId,
    required String doctorId,
    required String slotId,
    required String timeSlotId,
    String? notes,
  }) async {
    return ErrorHandler.guardAsync(() async {
      // 1. Validate all entities exist and are valid
      final validationResult = await _validateEntities(
        patientId: patientId,
        doctorId: doctorId,
        slotId: slotId,
        timeSlotId: timeSlotId,
      );

      if (validationResult.isFailure) {
        throw validationResult.error;
      }

      final entities = validationResult.data;
      final patient = entities['patient'] as Patient;
      final slot = entities['slot'] as AppointmentSlot;
      final timeSlot = entities['timeSlot'] as TimeSlot;

      // 2. Create appointment entity
      final appointment = Appointment(
        id: '', // Will be set by repository
        patientId: patientId,
        doctorId: doctorId,
        appointmentSlotId: slotId,
        timeSlotId: timeSlotId,
        dateTime: slot.date.copyWith(
          hour: timeSlot.startTime.hour,
          minute: timeSlot.startTime.minute,
        ),
        status: AppointmentStatus.scheduled,
        paymentStatus: PaymentStatus.unpaid,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Execute creation transaction
      final result = await _executeAppointmentCreation(
        appointment: appointment,
        patient: patient,
        slot: slot,
        timeSlot: timeSlot,
      );

      return result.data;
    }, 'creating appointment');
  }

  /// Updates an existing appointment
  Future<Result<Appointment>> updateAppointment({
    required String appointmentId,
    String? newSlotId,
    String? newTimeSlotId,
    AppointmentStatus? newStatus,
    PaymentStatus? newPaymentStatus,
    String? notes,
  }) async {
    return ErrorHandler.guardAsync(() async {
      // 1. Get and validate existing appointment
      final existingAppointmentResult = await _appointmentRepository.getById(
        appointmentId,
      );

      if (existingAppointmentResult.isFailure) {
        throw existingAppointmentResult.error;
      }

      final existingAppointment = existingAppointmentResult.data;
      if (existingAppointment == null) {
        throw 'Appointment not found';
      }

      // 2. Handle slot changes if needed
      if (newSlotId != null || newTimeSlotId != null) {
        final slotChangeResult = await _handleSlotChange(
          existingAppointment: existingAppointment,
          newSlotId: newSlotId ?? existingAppointment.appointmentSlotId,
          newTimeSlotId: newTimeSlotId ?? existingAppointment.timeSlotId,
        );

        if (slotChangeResult.isFailure) {
          throw slotChangeResult.error;
        }
      }

      // 3. Create updated appointment
      final updatedAppointment = existingAppointment.copyWith(
        status: newStatus ?? existingAppointment.status,
        paymentStatus: newPaymentStatus ?? existingAppointment.paymentStatus,
        notes: notes ?? existingAppointment.notes,
        appointmentSlotId: newSlotId ?? existingAppointment.appointmentSlotId,
        timeSlotId: newTimeSlotId ?? existingAppointment.timeSlotId,
        updatedAt: DateTime.now(),
      );

      // 4. Save updates
      final updateResult = await _appointmentRepository.update(
        updatedAppointment,
      );
      if (updateResult.isFailure) {
        throw updateResult.error;
      }

      // 5. Publish update event
      _eventBus.publish(
        AppointmentUpdatedEvent(updateResult.data, existingAppointment),
      );

      return updateResult.data;
    }, 'updating appointment');
  }

  /// Cancels an appointment
  Future<Result<void>> cancelAppointment(
    String appointmentId, {
    String? cancellationReason,
  }) async {
    return ErrorHandler.guardAsync(() async {
      // 1. Get and validate appointment
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

      if (appointment.status == AppointmentStatus.cancelled) {
        throw 'Appointment is already cancelled';
      }

      if (appointment.status == AppointmentStatus.completed) {
        throw 'Cannot cancel a completed appointment';
      }

      // 2. Release the time slot
      final slotResult = await _slotRepository.getById(
        appointment.appointmentSlotId,
      );
      if (slotResult.isFailure) {
        throw slotResult.error;
      }

      final slot = slotResult.data!;
      final updatedSlot = slot.cancelAppointment(
        appointment.timeSlotId,
        appointmentId,
      );

      final slotUpdateResult = await _slotRepository.update(updatedSlot);
      if (slotUpdateResult.isFailure) {
        throw slotUpdateResult.error;
      }

      // 3. Update appointment status
      final cancelledAppointment = appointment.copyWith(
        status: AppointmentStatus.cancelled,
        notes:
            cancellationReason != null
                ? '${appointment.notes}\nCancellation reason: $cancellationReason'
                : appointment.notes,
        updatedAt: DateTime.now(),
      );

      final updateResult = await _appointmentRepository.update(
        cancelledAppointment,
      );

      if (updateResult.isFailure) {
        throw updateResult.error;
      }

      // 4. Publish cancellation event
      _eventBus.publish(AppointmentCancelledEvent(updateResult.data.id));
    }, 'cancelling appointment');
  }

  /// Marks an appointment as completed
  Future<Result<Appointment>> completeAppointment(
    String appointmentId, {
    required PaymentStatus paymentStatus,
    String? completionNotes,
  }) async {
    return ErrorHandler.guardAsync(() async {
      // 1. Get and validate appointment
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

      if (appointment.status == AppointmentStatus.completed) {
        throw 'Appointment is already completed';
      }

      if (appointment.status == AppointmentStatus.cancelled) {
        throw 'Cannot complete a cancelled appointment';
      }

      // 2. Update appointment
      final completedAppointment = appointment.copyWith(
        status: AppointmentStatus.completed,
        paymentStatus: paymentStatus,
        notes:
            completionNotes != null
                ? '${appointment.notes}\nCompletion notes: $completionNotes'
                : appointment.notes,
        updatedAt: DateTime.now(),
      );

      final updateResult = await _appointmentRepository.update(
        completedAppointment,
      );

      if (updateResult.isFailure) {
        throw updateResult.error;
      }

      // 3. Publish completion event
      _eventBus.publish(AppointmentCompletedEvent(updateResult.data));

      return updateResult.data;
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

  /// Validates all entities exist and are valid for appointment creation
  Future<Result<Map<String, dynamic>>> _validateEntities({
    required String patientId,
    required String doctorId,
    required String slotId,
    required String timeSlotId,
  }) async {
    return ErrorHandler.guardAsync(() async {
      // 1. Validate patient
      final patientResult = await _patientRepository.getById(patientId);
      if (patientResult.isFailure) {
        throw patientResult.error;
      }

      final patient = patientResult.data;
      if (patient == null) {
        throw 'Patient not found';
      }

      if (patient.status != PatientStatus.active) {
        throw 'Patient is not active';
      }

      // 2. Validate doctor
      final doctorResult = await _doctorRepository.getById(doctorId);
      if (doctorResult.isFailure) {
        throw doctorResult.error;
      }

      final doctor = doctorResult.data;
      if (doctor == null) {
        throw 'Doctor not found';
      }

      if (!doctor.isAvailable) {
        throw 'Doctor is not active';
      }

      // 3. Validate slot and time slot
      // Add debug logging
      print('Validating slot $slotId and timeSlot $timeSlotId');

      final slotResult = await _slotRepository.getById(slotId);
      if (slotResult.isFailure) {
        throw slotResult.error;
      }

      final slot = slotResult.data;
      if (slot == null) {
        throw 'Appointment slot not found';
      }

      if (!slot.canAcceptBookings) {
        throw 'Appointment slot cannot accept bookings';
      }

      if (slot.doctorId != doctorId) {
        throw 'Slot does not belong to the specified doctor';
      }

      // Add debug logging for time slots
      print(
        'Available time slots: ${slot.timeSlots.map((ts) => ts.id).join(', ')}',
      );

      final timeSlot = slot.timeSlots.firstWhere(
        (ts) => ts.id == timeSlotId,
        orElse: () => throw 'Time slot not found',
      );

      if (!timeSlot.isActive) {
        throw 'Time slot is not active';
      }

      if (timeSlot.isFullyBooked) {
        throw 'Time slot is fully booked';
      }

      // 4. Check for existing appointments
      final existingAppointmentsResult = await _appointmentRepository
          .getByPatientId(patientId);

      if (existingAppointmentsResult.isFailure) {
        throw existingAppointmentsResult.error;
      }

      final hasConflict = existingAppointmentsResult.data.any(
        (a) =>
            a.status == AppointmentStatus.scheduled &&
            a.dateTime.isSameDate(slot.date),
      );

      if (hasConflict) {
        throw 'Patient already has an appointment scheduled for this date';
      }

      return {
        'patient': patient,
        'doctor': doctor,
        'slot': slot,
        'timeSlot': timeSlot,
      };
    }, 'validating entities');
  }

  /// Executes the appointment creation transaction
  Future<Result<Appointment>> _executeAppointmentCreation({
    required Appointment appointment,
    required Patient patient,
    required AppointmentSlot slot,
    required TimeSlot timeSlot,
  }) async {
    bool slotUpdated = false;
    bool appointmentCreated = false;
    String? appointmentId;

    try {
      // 1. Create the appointment
      final appointmentResult = await _appointmentRepository.create(
        appointment,
      );
      if (appointmentResult.isFailure) {
        throw appointmentResult.error;
      }

      final createdAppointment = appointmentResult.data;
      appointmentCreated = true;
      appointmentId = createdAppointment.id;

      // 2. Update the slot
      final updatedSlot = slot.bookAppointment(
        timeSlot.id,
        createdAppointment.id,
      );
      final slotUpdateResult = await _slotRepository.update(updatedSlot);

      if (slotUpdateResult.isFailure) {
        throw slotUpdateResult.error;
      }

      slotUpdated = true;

      // 3. Update patient's appointment references
      final updatedPatient = patient.copyWith(
        appointmentIds: [...patient.appointmentIds, createdAppointment.id],
      );

      final patientUpdateResult = await _patientRepository.update(
        updatedPatient,
      );
      if (patientUpdateResult.isFailure) {
        throw patientUpdateResult.error;
      }

      // 4. Publish creation event
      _eventBus.publish(AppointmentCreatedEvent(createdAppointment));

      return Result.success(createdAppointment);
    } catch (e) {
      // Rollback if needed
      await _rollbackCreation(
        slot: slot,
        timeSlotId: timeSlot.id,
        appointmentId: appointmentId,
        slotUpdated: slotUpdated,
        appointmentCreated: appointmentCreated,
      );
      rethrow;
    }
  }

  /// Handles slot changes during appointment updates
  Future<Result<void>> _handleSlotChange({
    required Appointment existingAppointment,
    required String newSlotId,
    required String newTimeSlotId,
  }) async {
    return ErrorHandler.guardAsync(() async {
      // 1. Validate new slot and time slot
      final newSlotResult = await _slotRepository.getById(newSlotId);
      if (newSlotResult.isFailure) {
        throw newSlotResult.error;
      }

      final newSlot = newSlotResult.data!;
      if (!newSlot.canAcceptBookings) {
        throw 'New slot cannot accept bookings';
      }

      final newTimeSlot = newSlot.timeSlots.firstWhere(
        (ts) => ts.id == newTimeSlotId,
        orElse: () => throw 'New time slot not found',
      );

      if (!newTimeSlot.isActive || newTimeSlot.isFullyBooked) {
        throw 'New time slot is not available';
      }

      // 2. Cancel old slot booking
      final oldSlotResult = await _slotRepository.getById(
        existingAppointment.appointmentSlotId,
      );

      if (oldSlotResult.isFailure) {
        throw oldSlotResult.error;
      }

      final oldSlot = oldSlotResult.data!;
      final cancelledSlot = oldSlot.cancelAppointment(
        existingAppointment.timeSlotId,
        existingAppointment.id,
      );

      final cancelResult = await _slotRepository.update(cancelledSlot);
      if (cancelResult.isFailure) {
        throw cancelResult.error;
      }

      // 3. Book new slot
      final bookedSlot = newSlot.bookAppointment(
        newTimeSlotId,
        existingAppointment.id,
      );

      final bookResult = await _slotRepository.update(bookedSlot);
      if (bookResult.isFailure) {
        // Try to restore old booking if new booking fails
        await _slotRepository.update(oldSlot).catchError((e) {
          return Result<AppointmentSlot>.failure(e.toString());
        });
        throw bookResult.error;
      }
    }, 'handling slot change');
  }

  /// Rolls back creation operations in case of failure
  Future<void> _rollbackCreation({
    required AppointmentSlot slot,
    required String timeSlotId,
    String? appointmentId,
    required bool slotUpdated,
    required bool appointmentCreated,
  }) async {
    if (slotUpdated && appointmentId != null) {
      await ErrorHandler.guardAsync(() async {
        final updatedSlot = slot.cancelAppointment(timeSlotId, appointmentId);
        await _slotRepository.update(updatedSlot);
      }, 'rolling back slot booking').catchError((error) {
        print('Failed to restore slot - $error');
        return Result<void>.failure(error.toString());
      });
    }

    if (appointmentCreated && appointmentId != null) {
      await ErrorHandler.guardAsync(() async {
        await _appointmentRepository.delete(appointmentId);
      }, 'rolling back appointment creation').catchError((error) {
        print('Failed to delete appointment - $error');
        return Result<void>.failure(error.toString());
      });
    }
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
