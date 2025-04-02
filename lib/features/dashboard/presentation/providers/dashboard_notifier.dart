// lib/features/dashboard/presentation/providers/dashboard_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../../appointment/domain/entities/appointment.dart';
import '../../../doctor/data/doctor_provider.dart';
import '../../../appointment/data/appointment_providers.dart';
import '../../../doctor/domain/entities/doctor.dart';

part 'dashboard_notifier.g.dart';

class DashboardState {
  final AsyncValue<List<Doctor>> doctors;
  final String? error;

  DashboardState({
    required this.doctors,
    this.error,
  });

  DashboardState copyWith({
    AsyncValue<List<Doctor>>? doctors,
    String? error,
  }) {
    return DashboardState(
      doctors: doctors ?? this.doctors,
      error: error,
    );
  }
}

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  @override
  Future<List<Doctor>> build() async {
    state = const AsyncLoading();
    final doctorRepository = ref.watch(doctorRepositoryProvider);
    
    final doctorsResult = await doctorRepository.getAll();
    
    if (doctorsResult.isFailure) {
      throw doctorsResult.error;
    }
    
    return doctorsResult.data;
  }

  Future<Result<List<Appointment>>> getAppointmentsForDoctor(String doctorId) async {
    return ErrorHandler.guardAsync(() async {
      // Check if doctorId is valid
      if (doctorId.isEmpty) {
        throw 'Doctor ID cannot be empty';
      }
      
      final appointmentRepository = ref.read(appointmentRepositoryProvider);
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final appointmentsResult = await appointmentRepository.getByDoctorId(doctorId);
      
      if (appointmentsResult.isFailure) {
        throw appointmentsResult.error;
      }
      
      final appointments = appointmentsResult.data;
      
      // Filter appointments for current week
      final weeklyAppointments = appointments.where((appointment) {
        return appointment.dateTime.isAfter(startOfWeek) &&
            appointment.dateTime.isBefore(endOfWeek);
      }).toList();
      
      return weeklyAppointments;
    }, 'getting appointments for doctor');
  }
  
  // Refresh doctor data
  Future<void> refreshDoctors() async {
    state = const AsyncLoading();
    
    try {
      final doctorRepository = ref.read(doctorRepositoryProvider);
      final doctorsResult = await doctorRepository.getAll();
      
      if (doctorsResult.isFailure) {
        throw doctorsResult.error;
      }
      
      state = AsyncData(doctorsResult.data);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
  
  // Get doctor statistics
  Future<Result<Map<String, dynamic>>> getDoctorStatistics() async {
    return ErrorHandler.guardAsync(() async {
      final doctorsValue = state;
      
      if (doctorsValue is AsyncError) {
        throw 'Failed to load doctors data';
      }
      
      if (doctorsValue is AsyncLoading) {
        throw 'Doctor data is still loading';
      }
      
      final doctors = doctorsValue.value!;
      
      // Calculate statistics
      final totalDoctors = doctors.length;
      final activeDoctors = doctors.where((doc) => doc.isAvailable).length;
      
      return {
        'totalDoctors': totalDoctors,
        'activeDoctors': activeDoctors,
        'inactiveDoctors': totalDoctors - activeDoctors,
        'availabilityPercentage': totalDoctors > 0 
            ? (activeDoctors / totalDoctors * 100).toStringAsFixed(1) 
            : '0',
      };
    }, 'calculating doctor statistics');
  }
}