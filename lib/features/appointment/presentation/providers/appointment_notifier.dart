// lib/features/appointment/presentation/providers/appointment_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
import '../../../doctor/data/doctor_provider.dart';
import '../../../doctor/domain/entities/doctor.dart';
import '../../../patient/data/patient_providers.dart';
import '../../../patient/domain/entities/patient.dart';
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
        state = state.copyWith(appointments: result.data, isLoading: false);
      } else {
        state = state.copyWith(error: result.error, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshAppointments() async {
    await loadAppointments();
  }

  // In appointment_notifier.dart - Update the createAppointment method
  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.createAppointment(
        patientId: appointment.patientId,
        doctorId: appointment.doctorId,
        slotId: appointment.appointmentSlotId,
        timeSlotId: appointment.timeSlotId,
      );

      if (result.isSuccess) {
        // Add the new appointment to the state instead of reloading all
        final updatedAppointments = [...state.appointments];
        updatedAppointments.add({
          'appointment': result.data,
          'patient': await _getPatient(result.data.patientId),
          'doctor': await _getDoctor(result.data.doctorId),
        });

        state = state.copyWith(
          appointments: updatedAppointments,
          isLoading: false,
        );
      } else {
        state = state.copyWith(error: result.error, isLoading: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return Result.failure(e.toString());
    }
  }

  // Add helper methods to get related data
  Future<Result<Patient?>> _getPatient(String id) async {
    return ref.read(patientRepositoryProvider).getById(id);
  }

  Future<Result<Doctor?>> _getDoctor(String id) async {
    return ref.read(doctorRepositoryProvider).getById(id);
  }

  Future<Result<Appointment>> updateAppointment(Appointment appointment) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.updateAppointment(
        appointmentId: appointment.id,
      );

      // Always refresh after attempt
      await loadAppointments();

      return result;
    } catch (e) {
      final errorMsg = e.toString();
      state = state.copyWith(isLoading: false, error: errorMsg);

      // Try to refresh anyway
      try {
        await loadAppointments();
      } catch (_) {}

      return Result.failure(errorMsg);
    }
  }

  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    // state = state.copyWith(isLoading: true, error: null);

    // try {
    //   final appointmentService = ref.read(appointmentServiceProvider);
    //   final result = await appointmentService.cancelAppointment(appointmentId);

    //   // Always refresh after attempt
    //   await loadAppointments();

    //   return result;
    // } catch (e) {
    //   final errorMsg = e.toString();
    //   state = state.copyWith(isLoading: false, error: errorMsg);

    //   // Try to refresh anyway
    //   try {
    //     await loadAppointments();
    //   } catch (_) {}

    //   return Result.failure(errorMsg);
    // }
    return Result.failure('errorMsg');
  }

  Future<Result<Appointment>> completeAppointment(
    String appointmentId, {
    String? notes,
    PaymentStatus paymentStatus = PaymentStatus.paid,
  }) async {
    try {
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.completeAppointment(
        appointmentId,
        completionNotes: notes,
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
    AppointmentStatus? status,
    String? patientId,
    String? doctorId,
    DateTime? date,
  }) {
    return state.appointments.where((item) {
      final appointment = item['appointment'] as Appointment;

      bool statusMatch = status == null || appointment.status == status;
      bool patientMatch =
          patientId == null || appointment.patientId == patientId;
      bool doctorMatch = doctorId == null || appointment.doctorId == doctorId;
      bool dateMatch = date == null || appointment.isSameDay(date);

      return statusMatch && patientMatch && doctorMatch && dateMatch;
    }).toList();
  }
}
