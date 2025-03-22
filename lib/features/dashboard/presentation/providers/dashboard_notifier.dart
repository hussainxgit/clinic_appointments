// lib/features/dashboard/presentation/providers/dashboard_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../appointment/domain/entities/appointment.dart';
import '../../../doctor/data/doctor_provider.dart';
import '../../../appointment/data/appointment_providers.dart';
import '../../../doctor/domain/entities/doctor.dart';

part 'dashboard_notifier.g.dart';

@riverpod
class DashboardNotifier extends _$DashboardNotifier {
  
  @override
  Future<List<Doctor>> build() async {
    final doctorRepository = ref.watch(doctorRepositoryProvider);
    return doctorRepository.getAll();
  }

  Future<List<Appointment>> getAppointmentsForDoctor(String doctorId) async {
    final appointmentRepository = ref.read(appointmentRepositoryProvider);
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final appointments = await appointmentRepository.getByDoctorId(doctorId);
    return appointments.where((appointment) {
      return appointment.dateTime.isAfter(startOfWeek) &&
          appointment.dateTime.isBefore(endOfWeek);
    }).toList();
  }
}
