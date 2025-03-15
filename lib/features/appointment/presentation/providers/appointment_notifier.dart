// lib/features/appointment/presentation/providers/appointment_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
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
  @override
  AppointmentState build() {
    // Return an initial state without loading
    state = AppointmentState(appointments: [], isLoading: false);
    loadAppointments();
    return state;
  }

  Future<void> loadAppointments() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the service to get appointment data
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.getCombinedAppointments();
      
      if (result.isSuccess) {
        state = state.copyWith(
          appointments: result.data,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: result.error,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshAppointments() async {
    await loadAppointments();
  }

  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    try {
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.createAppointment(appointment);

      if (result.isSuccess) {
        await loadAppointments();
      }
      return result;
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Appointment>> updateAppointment(Appointment appointment) async {
    try {
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.updateAppointment(appointment);

      if (result.isSuccess) {
        await loadAppointments();
      }
      return result;
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    try {
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.cancelAppointment(appointmentId);

      if (result.isSuccess) {
        await loadAppointments();
      }
      return result;
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Appointment>> completeAppointment(
    String appointmentId, {
    String? notes,
    String paymentStatus = 'paid',
  }) async {
    try {
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.completeAppointment(
        appointmentId,
        notes: notes,
        paymentStatus: paymentStatus,
      );

      if (result.isSuccess) {
        await loadAppointments();
      }
      return result;
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Filter appointments by different criteria
  List<Map<String, dynamic>> getFilteredAppointments({
    String? status,
    String? patientId,
    String? doctorId,
    DateTime? date,
  }) {
    return state.appointments.where((item) {
      final appointment = item['appointment'] as Appointment;
      
      bool statusMatch = status == null || appointment.status == status;
      bool patientMatch = patientId == null || appointment.patientId == patientId;
      bool doctorMatch = doctorId == null || appointment.doctorId == doctorId;
      bool dateMatch = date == null || appointment.isSameDay(date);
      
      return statusMatch && patientMatch && doctorMatch && dateMatch;
    }).toList();
  }
}