// lib/features/doctor/data/doctor_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'doctor_repository.dart';
import '../../../core/firebase/firebase_providers.dart'; // Import the file with firestoreProvider

part 'doctor_provider.g.dart';

@riverpod
DoctorRepository doctorRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return DoctorRepositoryImpl(firestore: firestore);
}
