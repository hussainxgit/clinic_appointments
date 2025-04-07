// lib/features/patient/presentation/providers/patient_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/utils/result.dart';
import '../../data/patient_providers.dart';
import '../../domain/entities/patient.dart';

part 'patient_notifier.g.dart';

class PatientState {
  final List<Patient> patients;
  final bool isLoading;
  final String? error;

  PatientState({required this.patients, this.isLoading = false, this.error});

  PatientState copyWith({
    List<Patient>? patients,
    bool? isLoading,
    String? error,
  }) {
    return PatientState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class PatientNotifier extends _$PatientNotifier {
  @override
  PatientState build() {
    // Return an initial state without loading
    state = PatientState(patients: [], isLoading: false);
    loadPatients();
    return state;
  }

  Future<void> loadPatients() async {
    state = state.copyWith(isLoading: true, error: null);
    final repository = ref.read(patientRepositoryProvider);
    final result = await repository.getAll();
    result.when(
      success: (patients) {
        state = state.copyWith(patients: patients, isLoading: false);
      },
      failure: (error) {
        state = state.copyWith(error: error, isLoading: false);
      },
    );
  }

  Future<void> refreshPatients() async {
    await loadPatients();
  }

  List<Patient> searchPatients(String query) {
    final searchTerm = query.toLowerCase().trim();
    if (searchTerm.isEmpty) return state.patients;

    return state.patients
        .where(
          (patient) =>
              patient.name.toLowerCase().contains(searchTerm) ||
              patient.phone.toLowerCase().contains(searchTerm) ||
              (patient.email?.toLowerCase().contains(searchTerm) ?? false),
        )
        .toList();
  }

  Future<Result<Patient>> addPatient(Patient patient) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(patientRepositoryProvider);

      // Check for existing patient with same phone
      final existingPatientResult = await repository.findByPhone(patient.phone);

      if (existingPatientResult.isSuccess &&
          existingPatientResult.data != null) {
        return Result.failure(
          'A patient with this phone number already exists',
        );
      }

      final result = await repository.create(patient);

      if (result.isSuccess) {
        // Update local state directly
        state = state.copyWith(patients: [...state.patients, result.data]);
      } else {
        state = state.copyWith(error: result.error);
      }

      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return Result.failure('Unexpected error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<Result<Patient>> updatePatient(Patient patient) async {
    state = state.copyWith(isLoading: true, error: null);

    final repository = ref.read(patientRepositoryProvider);

    final index = state.patients.indexWhere((p) => p.id == patient.id);
    if (index == -1) {
      state = state.copyWith(isLoading: false);
      return Result.failure('Patient not found');
    }

    // Check for phone uniqueness (excluding current patient)
    final samePhone = state.patients.firstWhere(
      (p) => p.phone == patient.phone && p.id != patient.id,
      orElse: () => patient, // Return same patient if not found
    );

    if (samePhone.id != patient.id) {
      state = state.copyWith(isLoading: false);
      return Result.failure('Phone number already in use');
    }

    final result = await repository.update(patient);

    state = state.copyWith(isLoading: false);

    if (result.isSuccess) {
      // Update the specific patient in the state
      final updatedPatients = [...state.patients];
      updatedPatients[index] = result.data;
      state = state.copyWith(patients: updatedPatients);

      // Publish patient updated event
      ref.read(eventBusProvider).publish(PatientUpdatedEvent(result.data));
    }

    return result;
  }

  Future<Result<bool>> deletePatient(String id) async {
    try {
      final repository = ref.read(patientRepositoryProvider);

      final index = state.patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Result.failure('Patient not found');
      }

      final result = await repository.delete(id);

      if (result.isSuccess) {
        // Remove the patient from local state
        final updatedPatients = [...state.patients];
        updatedPatients.removeAt(index);
        state = state.copyWith(patients: updatedPatients);
      }

      return Result.success(true);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Patient>> toggleStatus(String id) async {
    try {
      final repository = ref.read(patientRepositoryProvider);

      final index = state.patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Result.failure('Patient not found');
      }

      final patient = state.patients[index];
      final newStatus =
          patient.status == PatientStatus.active
              ? PatientStatus.inactive
              : PatientStatus.active;

      final updatedPatient = patient.copyWith(status: newStatus);
      final result = await repository.update(updatedPatient);

      // Update the patient in the local state
      final updatedPatients = [...state.patients];
      updatedPatients[index] = result.data;
      state = state.copyWith(patients: updatedPatients);

      return Result.success(result.data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Patient>> addAppointmentReference(
    String patientId,
    String appointmentId,
  ) async {
    try {
      final repository = ref.read(patientRepositoryProvider);

      final index = state.patients.indexWhere((p) => p.id == patientId);
      if (index == -1) {
        return Result.failure('Patient not found');
      }

      final patient = state.patients[index];

      // Check if appointment already exists in the patient's list
      if (patient.appointmentIds.contains(appointmentId)) {
        return Result.success(patient); // Already added, no need to update
      }

      // Add appointment to patient's list
      final updatedAppointmentIds = List<String>.from(patient.appointmentIds)
        ..add(appointmentId);
      final updatedPatient = patient.copyWith(
        appointmentIds: updatedAppointmentIds,
      );

      // Update in repository
      final savedPatient = await repository.update(updatedPatient);

      // Update local state
      final updatedPatients = [...state.patients];
      updatedPatients[index] = savedPatient.data;
      state = state.copyWith(patients: updatedPatients);

      return Result.success(savedPatient.data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Patient>> removeAppointmentReference(
    String patientId,
    String appointmentId,
  ) async {
    try {
      final repository = ref.read(patientRepositoryProvider);

      final index = state.patients.indexWhere((p) => p.id == patientId);
      if (index == -1) {
        return Result.failure('Patient not found');
      }

      final patient = state.patients[index];

      // Check if appointment is in the patient's list
      if (!patient.appointmentIds.contains(appointmentId)) {
        return Result.success(patient); // Not in the list, no need to update
      }

      // Remove appointment from patient's list
      final updatedAppointmentIds = List<String>.from(patient.appointmentIds)
        ..remove(appointmentId);
      final updatedPatient = patient.copyWith(
        appointmentIds: updatedAppointmentIds,
      );

      // Update in repository
      final savedPatient = await repository.update(updatedPatient);

      // Update local state
      final updatedPatients = [...state.patients];
      updatedPatients[index] = savedPatient.data;
      state = state.copyWith(patients: updatedPatients);

      return Result.success(savedPatient.data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
