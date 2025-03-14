// lib/features/appointment/data/appointment_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'appointment_repository.dart';
import '../../../core/firebase/firebase_providers.dart';

part 'appointment_providers.g.dart';

@riverpod
AppointmentRepository appointmentRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return AppointmentRepositoryImpl(firestore: firestore);
}