// lib/features/appointment/domain/services/appointment_service.dart
import '../../../../core/utils/result.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/events/event_bus.dart';
import '../../../../core/events/domain_events.dart';
import '../../appointment_slot/data/appointment_slot_repository.dart';
import '../../appointment_slot/presentation/providers/appointment_slot_provider.dart';
import '../../doctor/data/doctor_repository.dart';
import '../../patient/data/patient_repository.dart';
import '../../patient/presentation/providers/patient_provider.dart';
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
  
  // Create a new appointment with full validation and coordination
  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    try {
      // 1. Validate patient exists
      final patient = await _patientRepository.getById(appointment.patientId);
      if (patient == null) {
        return Result.failure('Patient not found');
      }
      
      // 2. Validate doctor exists
      final doctor = await _doctorRepository.getById(appointment.doctorId);
      if (doctor == null) {
        return Result.failure('Doctor not found');
      }
      
      // 3. Check if doctor is available
      if (!doctor.isAvailable) {
        return Result.failure('Doctor is not available for appointments');
      }
      
      // 4. Validate slot exists
      final slot = await _slotRepository.getById(appointment.appointmentSlotId);
      if (slot == null) {
        return Result.failure('Appointment slot not found');
      }
      
      // 5. Check if slot is available
      if (slot.isFullyBooked) {
        return Result.failure('Appointment slot is fully booked');
      }
      
      // 6. Check if patient already has appointment on same day
      final patientAppointments = await _appointmentRepository.getByPatientId(appointment.patientId);
      final sameDay = patientAppointments.any((a) => 
        a.status == 'scheduled' && a.isSameDay(appointment.dateTime));
      
      if (sameDay) {
        return Result.failure('Patient already has an appointment on this day');
      }
      
      // 7. Book the slot first
      final slotProvider = ServiceLocator.get<AppointmentSlotProvider>();
      final slotResult = await slotProvider.bookSlot(
        appointment.appointmentSlotId, 
        appointment.id
      );
      
      if (slotResult.isFailure) {
        return Result.failure('Failed to book slot: ${slotResult.error}');
      }
      
      // 8. Add appointment
      final savedAppointment = await _appointmentRepository.create(appointment);
      
      // 9. Update patient with appointment reference
      final patientProvider = ServiceLocator.get<PatientProvider>();
      await patientProvider.addAppointmentReference(
        appointment.patientId, 
        appointment.id
      );
      
      // 10. Publish event
      _eventBus.publish(AppointmentCreatedEvent(savedAppointment));
      
      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Update an existing appointment
  Future<Result<Appointment>> updateAppointment(Appointment updatedAppointment) async {
    try {
      // 1. Find the existing appointment
      final existingAppointment = await _appointmentRepository.getById(updatedAppointment.id);
      if (existingAppointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // 2. If slot changed, handle slot booking changes
      if (existingAppointment.appointmentSlotId != updatedAppointment.appointmentSlotId) {
        // Cancel old slot
        final slotProvider = ServiceLocator.get<AppointmentSlotProvider>();
        final cancelResult = await slotProvider.cancelSlot(
          existingAppointment.appointmentSlotId,
          existingAppointment.id
        );
        
        if (cancelResult.isFailure) {
          return Result.failure('Failed to cancel previous slot: ${cancelResult.error}');
        }
        
        // Book new slot
        final bookResult = await slotProvider.bookSlot(
          updatedAppointment.appointmentSlotId,
          updatedAppointment.id
        );
        
        if (bookResult.isFailure) {
          // Try to revert the cancellation
          await slotProvider.bookSlot(
            existingAppointment.appointmentSlotId,
            existingAppointment.id
          );
          return Result.failure('Failed to book new slot: ${bookResult.error}');
        }
      }
      
      // 3. If patient changed, update patient references
      if (existingAppointment.patientId != updatedAppointment.patientId) {
        final patientProvider = ServiceLocator.get<PatientProvider>();
        
        // Remove reference from old patient
        await patientProvider.removeAppointmentReference(
          existingAppointment.patientId,
          existingAppointment.id
        );
        
        // Add reference to new patient
        await patientProvider.addAppointmentReference(
          updatedAppointment.patientId,
          updatedAppointment.id
        );
      }
      
      // 4. Save updated appointment
      final savedAppointment = await _appointmentRepository.update(updatedAppointment);
      
      // 5. Publish event
      _eventBus.publish(AppointmentUpdatedEvent(savedAppointment, existingAppointment));
      
      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Cancel an appointment
  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    try {
      // 1. Find the appointment
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // 2. Ensure it's not already cancelled
      if (appointment.status == 'cancelled') {
        return Result.failure('Appointment is already cancelled');
      }
      
      // 3. Update appointment status
      final updatedAppointment = appointment.copyWith(status: 'cancelled');
      await _appointmentRepository.update(updatedAppointment);
      
      // 4. Cancel the slot booking
      final slotProvider = ServiceLocator.get<AppointmentSlotProvider>();
      await slotProvider.cancelSlot(
        appointment.appointmentSlotId,
        appointmentId
      );
      
      // 5. Publish event
      _eventBus.publish(AppointmentCancelledEvent(appointmentId));
      
      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Complete an appointment
  Future<Result<Appointment>> completeAppointment(
    String appointmentId, 
    {String? notes, String paymentStatus = 'paid'}
  ) async {
    try {
      // 1. Find the appointment
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) {
        return Result.failure('Appointment not found');
      }
      
      // 2. Ensure it's not already completed or cancelled
      if (appointment.status == 'completed') {
        return Result.failure('Appointment is already completed');
      }
      if (appointment.status == 'cancelled') {
        return Result.failure('Cannot complete a cancelled appointment');
      }
      
      // 3. Update appointment
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        paymentStatus: paymentStatus,
        notes: notes ?? appointment.notes,
      );
      
      final savedAppointment = await _appointmentRepository.update(updatedAppointment);
      
      // 4. Publish event
      _eventBus.publish(AppointmentCompletedEvent(savedAppointment));
      
      return Result.success(savedAppointment);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Get combined appointment data with patient and doctor info
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