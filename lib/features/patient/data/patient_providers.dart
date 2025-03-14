// lib/features/patient/data/patient_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'patient_repository.dart';
import '../../../core/firebase/firebase_providers.dart';

part 'patient_providers.g.dart';

@riverpod
PatientRepository patientRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return PatientRepositoryImpl(firestore: firestore);
}