// lib/features/appointment/presentation/providers/appointment_notifier.dart
import 'package:clinic_appointments/core/di/core_providers.dart';
import 'package:clinic_appointments/features/appointment_slot/data/appointment_slot_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
import '../../data/appointment_providers.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../doctor/data/doctor_provider.dart';
import '../../domain/entities/appointment.dart';
import '../../services/appointment_service.dart';

part 'appointment_notifier.g.dart';

class AppointmentState {
  final List<Map<String, dynamic>> appointments;
  final bool isLoading;
  final String? error;

  AppointmentState({
    required this.appointments,
    this.isLoading = false,
    this.error,
  });

  AppointmentState copyWith({
    List<Map<String, dynamic>>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class AppointmentNotifier extends _$AppointmentNotifier {
  late AppointmentService _appointmentService;

  @override
  AppointmentState build() {
    _initializeService();
    _loadAppointments();
    return AppointmentState(appointments: [], isLoading: true);
  }

  void _initializeService() {
    final appointmentRepo = ref.read(appointmentRepositoryProvider);
    final patientRepo = ref.read(patientRepositoryProvider);
    final doctorRepo = ref.read(doctorRepositoryProvider);
    
    _appointmentService = AppointmentService(
      appointmentRepository: appointmentRepo,
      patientRepository: patientRepo,
      doctorRepository: doctorRepo,
      slotRepository: ref.read(appointmentSlotRepositoryProvider),
      eventBus: ref.read(eventBusProvider),
    );
  }

  Future<void> _loadAppointments() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _appointmentService.getCombinedAppointments();
      
      if (result.isSuccess) {
        state = state.copyWith(
          appointments: result.data, 
          isLoading: false
        );
      } else {
        state = state.copyWith(
          error: result.error, 
          isLoading: false
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(), 
        isLoading: false
      );
    }
  }

  Future<void> refreshAppointments() async {
    await _loadAppointments();
  }

  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    try {
      final result = await _appointmentService.createAppointment(appointment);
      
      if (result.isSuccess) {
        await _loadAppointments();
        return result;
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Appointment>> updateAppointment(Appointment appointment) async {
    try {
      final result = await _appointmentService.updateAppointment(appointment);
      
      if (result.isSuccess) {
        await _loadAppointments();
        return result;
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    try {
      final result = await _appointmentService.cancelAppointment(appointmentId);
      
      if (result.isSuccess) {
        await _loadAppointments();
        return result;
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Appointment>> completeAppointment(
    String appointmentId, 
    {String? notes, String paymentStatus = 'paid'}
  ) async {
    try {
      final result = await _appointmentService.completeAppointment(
        appointmentId,
        notes: notes,
        paymentStatus: paymentStatus
      );
      
      if (result.isSuccess) {
        await _loadAppointments();
        return result;
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}