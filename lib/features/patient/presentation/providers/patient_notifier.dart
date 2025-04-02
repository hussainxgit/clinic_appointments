// lib/features/patient/presentation/providers/patient_notifier.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

    try {
      final repository = ref.read(patientRepositoryProvider);
      final patients = await repository.getAll();
      state = state.copyWith(patients: patients, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
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
    try {
      final repository = ref.read(patientRepositoryProvider);

      // Check for existing patient with same phone
      final existingPatient = await repository.findByPhone(patient.phone);
      if (existingPatient != null) {
        return Result.failure(
          'A patient with this phone number already exists',
        );
      }

      final savedPatient = await repository.create(patient);

      // Update local state directly instead of reloading all patients
      state = state.copyWith(patients: [...state.patients, savedPatient]);

      return Result.success(savedPatient);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Patient>> updatePatient(Patient patient) async {
    try {
      final repository = ref.read(patientRepositoryProvider);

      final index = state.patients.indexWhere((p) => p.id == patient.id);
      if (index == -1) {
        return Result.failure('Patient not found');
      }

      // Check for phone uniqueness (excluding current patient)
      final samePhone = state.patients.firstWhere(
        (p) => p.phone == patient.phone && p.id != patient.id,
        orElse: () => patient, // Return same patient if not found
      );

      if (samePhone.id != patient.id) {
        return Result.failure('Phone number already in use');
      }

      final updatedPatient = await repository.update(patient);

      // Update the specific patient in the state
      final updatedPatients = [...state.patients];
      updatedPatients[index] = updatedPatient;
      state = state.copyWith(patients: updatedPatients);

      return Result.success(updatedPatient);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> deletePatient(String id) async {
    try {
      final repository = ref.read(patientRepositoryProvider);

      final index = state.patients.indexWhere((p) => p.id == id);
      if (index == -1) {
        return Result.failure('Patient not found');
      }

      final result = await repository.delete(id);

      if (result) {
        // Remove the patient from local state
        final updatedPatients = [...state.patients];
        updatedPatients.removeAt(index);
        state = state.copyWith(patients: updatedPatients);
      }

      return Result.success(result);
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
      updatedPatients[index] = result;
      state = state.copyWith(patients: updatedPatients);

      return Result.success(result);
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
      updatedPatients[index] = savedPatient;
      state = state.copyWith(patients: updatedPatients);

      return Result.success(savedPatient);
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
      updatedPatients[index] = savedPatient;
      state = state.copyWith(patients: updatedPatients);

      return Result.success(savedPatient);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
