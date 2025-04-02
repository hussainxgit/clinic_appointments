// lib/features/doctor/presentation/provider/doctor_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
import '../../data/doctor_provider.dart';
import '../../domain/entities/doctor.dart';

part 'doctor_notifier.g.dart';

class DoctorState {
  final List<Doctor> doctors;
  final bool isLoading;
  final String? error;

  DoctorState({required this.doctors, this.isLoading = false, this.error});

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
    state = DoctorState(doctors: [], isLoading: true);
    loadDoctors();
    return state;
  }

  Future<void> loadDoctors() async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(doctorRepositoryProvider);
    final result = await repository.getAll();

    result.when(
      success: (doctors) {
        state = state.copyWith(doctors: doctors, isLoading: false);
      },
      failure: (errorMessage) {
        state = state.copyWith(error: errorMessage, isLoading: false);
      },
    );
  }

  Future<void> refreshDoctors() async {
    await loadDoctors();
  }

  Future<Result<Doctor>> addDoctor(Doctor doctor) async {
    state = state.copyWith(isLoading: true, error: null);

    // Validate business rules
    if (state.doctors.any((d) => d.id == doctor.id)) {
      state = state.copyWith(isLoading: false);
      return Result.failure('A doctor with this ID already exists');
    }

    if (state.doctors.any((d) => d.name == doctor.name)) {
      state = state.copyWith(isLoading: false);
      return Result.failure('A doctor with this name already exists');
    }

    // Perform operation
    final repository = ref.read(doctorRepositoryProvider);
    final result = await repository.create(doctor);

    state = state.copyWith(isLoading: false);

    // Update state if successful
    if (result.isSuccess) {
      state = state.copyWith(doctors: [...state.doctors, result.data]);
    }

    return result;
  }

  Future<Result<Doctor>> updateDoctor(Doctor doctor) async {
    state = state.copyWith(isLoading: true, error: null);

    // Validate business rules
    if (!state.doctors.any((d) => d.id == doctor.id)) {
      state = state.copyWith(isLoading: false);
      return Result.failure('Doctor not found');
    }

    if (state.doctors.any((d) => d.name == doctor.name && d.id != doctor.id)) {
      state = state.copyWith(isLoading: false);
      return Result.failure('A doctor with this name already exists');
    }

    // Perform operation
    final repository = ref.read(doctorRepositoryProvider);
    final result = await repository.update(doctor);

    state = state.copyWith(isLoading: false);

    // Update state if successful
    if (result.isSuccess) {
      final index = state.doctors.indexWhere((d) => d.id == doctor.id);
      if (index >= 0) {
        final updatedDoctors = [...state.doctors];
        updatedDoctors[index] = result.data;
        state = state.copyWith(doctors: updatedDoctors);
      }
    }

    return result;
  }

  Future<Result<void>> deleteDoctor(String doctorId) async {
    state = state.copyWith(isLoading: true, error: null);

    // Validate business rules
    if (!state.doctors.any((d) => d.id == doctorId)) {
      state = state.copyWith(isLoading: false);
      return Result.failure('Doctor not found');
    }

    // Perform operation
    final repository = ref.read(doctorRepositoryProvider);
    final result = await repository.delete(doctorId);

    state = state.copyWith(isLoading: false);

    // Update state if successful
    if (result.isSuccess && result.data) {
      state = state.copyWith(
        doctors: state.doctors.where((d) => d.id != doctorId).toList(),
      );
      return Result.success(null);
    }

    return Result.failure(result.error);
  }
}
