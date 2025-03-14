// lib/features/appointment/services/appointment_service.dart
import '../../../../core/utils/result.dart';
import '../../../../core/events/event_bus.dart';
import '../../../../core/events/domain_events.dart';
import '../../appointment_slot/data/appointment_slot_repository.dart';
import '../../patient/data/patient_repository.dart';
import '../../doctor/data/doctor_repository.dart';
import '../data/appointment_repository.dart';
import '../domain/entities/appointment.dart';

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
  
  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    try {
      // 1. Validate patient exists
      final patient = await _patientRepository.getById(appointment.patientId);
      if (patient == null) {
        return Result.failure('Patient not found');
      }
      
      // 2. Validate doctor exists and is available
      final doctor = await _doctorRepository.getById(appointment.doctorId);
      if (doctor == null) {
        return Result.failure('Doctor not found');
      }
      
      if (!doctor.isAvailable) {
        return Result.failure('Doctor is not available');
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
      
      // 5. Book the slot
      final updatedSlot = slot.bookAppointment(appointment.id);
      await _slotRepository.update(updatedSlot);
      
      // 6. Create appointment
      final savedAppointment = await _appointmentRepository.create(appointment);
      
      // 7. Update patient's appointment references
      final updatedPatient = patient.copyWith(
        appointmentIds: [...patient.appointmentIds, savedAppointment.id]
      );
      await _patientRepository.update(updatedPatient);
      
      // 8. Publish creation event
      _eventBus.publish(AppointmentCreatedEvent(savedAppointment));
      
      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  Future<Result<Appointment>> updateAppointment(Appointment updatedAppointment) async {
    try {
      // 1. Find existing appointment
      final existingAppointment = await _appointmentRepository.getById(updatedAppointment.id);
      if (existingAppointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // 2. Validate doctor
      final doctor = await _doctorRepository.getById(updatedAppointment.doctorId);
      if (doctor == null) {
        return Result.failure('Doctor not found');
      }
      
      if (!doctor.isAvailable) {
        return Result.failure('Doctor is not available');
      }
      
      // 3. Handle slot changes if needed
      if (existingAppointment.appointmentSlotId != updatedAppointment.appointmentSlotId) {
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
      }
      
      // 4. Handle patient changes if needed
      if (existingAppointment.patientId != updatedAppointment.patientId) {
        // Remove from old patient
        final oldPatient = await _patientRepository.getById(existingAppointment.patientId);
        if (oldPatient != null) {
          final updatedOldPatient = oldPatient.copyWith(
            appointmentIds: oldPatient.appointmentIds..remove(existingAppointment.id)
          );
          await _patientRepository.update(updatedOldPatient);
        }
        
        // Add to new patient
        final newPatient = await _patientRepository.getById(updatedAppointment.patientId);
        if (newPatient == null) {
          return Result.failure('New patient not found');
        }
        
        final updatedNewPatient = newPatient.copyWith(
          appointmentIds: [...newPatient.appointmentIds, updatedAppointment.id]
        );
        await _patientRepository.update(updatedNewPatient);
      }
      
      // 5. Update appointment
      final savedAppointment = await _appointmentRepository.update(updatedAppointment);
      
      // 6. Publish update event
      _eventBus.publish(AppointmentUpdatedEvent(savedAppointment, existingAppointment));
      
      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    try {
      // 1. Find appointment
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // 2. Update appointment status
      final cancelledAppointment = appointment.copyWith(status: 'cancelled');
      await _appointmentRepository.update(cancelledAppointment);
      
      // 3. Cancel slot booking
      final slot = await _slotRepository.getById(appointment.appointmentSlotId);
      if (slot != null) {
        final updatedSlot = slot.cancelAppointment(appointmentId);
        await _slotRepository.update(updatedSlot);
      }
      
      // 4. Remove from patient's appointments
      final patient = await _patientRepository.getById(appointment.patientId);
      if (patient != null) {
        final updatedPatient = patient.copyWith(
          appointmentIds: patient.appointmentIds..remove(appointmentId)
        );
        await _patientRepository.update(updatedPatient);
      }
      
      // 5. Publish cancellation event
      _eventBus.publish(AppointmentCancelledEvent(appointmentId));
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  Future<Result<Appointment>> completeAppointment(
    String appointmentId, 
    {String? notes, String paymentStatus = 'paid'}
  ) async {
    try {
      // 1. Find appointment
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // 2. Validate current status
      if (appointment.status == 'completed') {
        return Result.failure('Appointment is already completed');
      }
      
      if (appointment.status == 'cancelled') {
        return Result.failure('Cannot complete a cancelled appointment');
      }
      
      // 3. Update appointment
      final completedAppointment = appointment.copyWith(
        status: 'completed',
        paymentStatus: paymentStatus,
        notes: notes ?? appointment.notes,
      );
      
      final savedAppointment = await _appointmentRepository.update(completedAppointment);
      
      // 4. Publish completion event
      _eventBus.publish(AppointmentCompletedEvent(savedAppointment));
      
      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Get appointments with related data
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
      
      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}