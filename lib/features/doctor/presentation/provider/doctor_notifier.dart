// lib/features/doctor/controller/doctor_notifier.dart
import 'package:clinic_appointments/core/utils/result.dart';
import 'package:clinic_appointments/features/doctor/data/doctor_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/doctor.dart';

part 'doctor_notifier.g.dart';

class DoctorState {
  final List<Doctor> doctors;
  final bool isLoading;
  final String? error;

  DoctorState({
    required this.doctors,
    this.isLoading = false,
    this.error,
  });

  DoctorState copyWith({
    List<Doctor>? doctors,
    bool? isLoading,
    String? error,
  }) {
    return DoctorState(
      doctors: doctors ?? this.doctors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class DoctorNotifier extends _$DoctorNotifier {
  @override
  DoctorState build() {
    _loadDoctors();
    return DoctorState(doctors: [], isLoading: true);
  }

  Future<void> _loadDoctors() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final repository = ref.read(doctorRepositoryProvider);
      final doctors = await repository.getAll();
      state = state.copyWith(doctors: doctors, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshDoctors() async {
    await _loadDoctors();
  }

  Future<Result<Doctor>> addDoctor(Doctor doctor) async {
    try {
      final repository = ref.read(doctorRepositoryProvider);
      
      if (state.doctors.any((d) => d.id == doctor.id)) {
        return Result.failure('A doctor with this ID already exists');
      }
      
      if (state.doctors.any((d) => d.name == doctor.name)) {
        return Result.failure('A doctor with this name already exists');
      }
      
      final savedDoctor = await repository.create(doctor);
      state = state.copyWith(doctors: [...state.doctors, savedDoctor]);
      return Result.success(savedDoctor);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Doctor>> updateDoctor(Doctor doctor) async {
    try {
      final repository = ref.read(doctorRepositoryProvider);
      
      final index = state.doctors.indexWhere((d) => d.id == doctor.id);
      if (index == -1) {
        return Result.failure('Doctor not found');
      }
      
      if (state.doctors.any((d) => d.name == doctor.name && d.id != doctor.id)) {
        return Result.failure('A doctor with this name already exists');
      }
      
      final updatedDoctor = await repository.update(doctor);
      
      final updatedDoctors = [...state.doctors];
      updatedDoctors[index] = updatedDoctor;
      state = state.copyWith(doctors: updatedDoctors);
      
      return Result.success(updatedDoctor);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  // Add other methods as needed
}