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
  }) : 
    _appointmentRepository = appointmentRepository,
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
  Future<Result<Appointment>> updateAppointment(Appointment updatedAppointment) async {
    try {
      // Find and validate the existing appointment
      final existingAppointment = await _appointmentRepository.getById(updatedAppointment.id);
      if (existingAppointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // Validate doctor
      final doctorResult = await _validateDoctor(updatedAppointment.doctorId);
      if (doctorResult.isFailure) {
        return Result.failure(doctorResult.error);
      }
      
      // Handle slot changes
      if (existingAppointment.appointmentSlotId != updatedAppointment.appointmentSlotId) {
        final slotChangeResult = await _handleSlotChange(
          existingAppointment,
          updatedAppointment
        );
        if (slotChangeResult.isFailure) {
          return Result.failure(slotChangeResult.error);
        }
      }
      
      // Handle patient changes
      if (existingAppointment.patientId != updatedAppointment.patientId) {
        final patientChangeResult = await _handlePatientChange(
          existingAppointment,
          updatedAppointment
        );
        if (patientChangeResult.isFailure) {
          return Result.failure(patientChangeResult.error);
        }
      }
      
      // Update the appointment
      final savedAppointment = await _appointmentRepository.update(updatedAppointment);
      
      // Publish update event
      _eventBus.publish(AppointmentUpdatedEvent(savedAppointment, existingAppointment));
      
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
      final cancelledAppointment = appointment.copyWith(status: 'cancelled');
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
    String appointmentId, 
    {String? notes, String paymentStatus = 'paid'}
  ) async {
    try {
      // Find appointment
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // Validate current status
      if (appointment.status == 'completed') {
        return Result.failure('Appointment is already completed');
      }
      
      if (appointment.status == 'cancelled') {
        return Result.failure('Cannot complete a cancelled appointment');
      }
      
      // Update appointment
      final completedAppointment = appointment.copyWith(
        status: 'completed',
        paymentStatus: paymentStatus,
        notes: notes ?? appointment.notes,
      );
      
      final savedAppointment = await _appointmentRepository.update(completedAppointment);
      
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
    Appointment appointment
  ) async {
    // 1. Validate patient exists
    final patient = await _patientRepository.getById(appointment.patientId);
    if (patient == null) {
      return Result.failure('Patient not found');
    }
    
    // 2. Validate doctor exists and is available
    final doctorResult = await _validateDoctor(appointment.doctorId);
    if (doctorResult.isFailure) {
      return Result.failure(doctorResult.error);
    }
    
    // 3. Validate slot
    final slot = await _slotRepository.getById(appointment.appointmentSlotId);
    if (slot == null) {
      return Result.failure('Appointment slot not found');
    }
    
    if (slot.isFullyBooked) {
      return Result.failure('Appointment slot is fully booked');
    }
    
    // 4. Check patient doesn't have another appointment on the same day
    final patientAppointments = await _appointmentRepository.getByPatientId(appointment.patientId);
    final sameDay = patientAppointments.any((a) => 
      a.status == 'scheduled' && a.isSameDay(appointment.dateTime));
    
    if (sameDay) {
      return Result.failure('Patient already has an appointment on this day');
    }
    
    return Result.success({
      'patient': patient,
      'slot': slot,
    });
  }
  
  /// Execute appointment creation after validation
  Future<Result<Appointment>> _executeAppointmentCreation(
    Appointment appointment,
    dynamic patient,
    dynamic slot
  ) async {
    try {
      // 1. Book the slot
      final updatedSlot = slot.bookAppointment(appointment.id);
      await _slotRepository.update(updatedSlot);
      
      // 2. Create appointment
      final savedAppointment = await _appointmentRepository.create(appointment);
      
      // 3. Update patient's appointment references
      final updatedPatient = patient.copyWith(
        appointmentIds: [...patient.appointmentIds, savedAppointment.id]
      );
      await _patientRepository.update(updatedPatient);
      
      // 4. Publish creation event
      _eventBus.publish(AppointmentCreatedEvent(savedAppointment));
      
      return Result.success(savedAppointment);
    } catch (e) {
      // At this point, we might have partial updates.
      // In a production app, you might want to add rollback logic here,
      // or use Firebase transactions for atomicity.
      return Result.failure('Error creating appointment: ${e.toString()}');
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
    Appointment updatedAppointment
  ) async {
    try {
      // Cancel old slot
      final oldSlot = await _slotRepository.getById(existingAppointment.appointmentSlotId);
      if (oldSlot != null) {
        final cancelledSlot = oldSlot.cancelAppointment(existingAppointment.id);
        await _slotRepository.update(cancelledSlot);
      }
      
      // Book new slot
      final newSlot = await _slotRepository.getById(updatedAppointment.appointmentSlotId);
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
      return Result.failure('Failed to update appointment slots: ${e.toString()}');
    }
  }
  
  /// Handle changes to the patient when updating an appointment
  Future<Result<void>> _handlePatientChange(
    Appointment existingAppointment,
    Appointment updatedAppointment
  ) async {
    try {
      // Remove from old patient
      await _removeAppointmentFromPatient(
        existingAppointment.patientId, 
        existingAppointment.id
      );
      
      // Add to new patient
      final newPatient = await _patientRepository.getById(updatedAppointment.patientId);
      if (newPatient == null) {
        return Result.failure('New patient not found');
      }
      
      final updatedNewPatient = newPatient.copyWith(
        appointmentIds: [...newPatient.appointmentIds, updatedAppointment.id]
      );
      await _patientRepository.update(updatedNewPatient);
      
      return Result.success(null);
    } catch (e) {
      return Result.failure('Failed to update patient references: ${e.toString()}');
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
  Future<void> _removeAppointmentFromPatient(String patientId, String appointmentId) async {
    final patient = await _patientRepository.getById(patientId);
    if (patient != null) {
      final updatedPatient = patient.copyWith(
        appointmentIds: patient.appointmentIds..remove(appointmentId)
      );
      await _patientRepository.update(updatedPatient);
    }
  }
  
  /// Attach patient and doctor data to a list of appointments
  Future<List<Map<String, dynamic>>> _attachRelatedData(List<Appointment> appointments) async {
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