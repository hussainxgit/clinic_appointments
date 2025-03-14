// lib/features/appointment_slot/data/appointment_slot_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'appointment_slot_repository.dart';
import '../../../core/firebase/firebase_providers.dart';

part 'appointment_slot_providers.g.dart';

@riverpod
AppointmentSlotRepository appointmentSlotRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return AppointmentSlotRepositoryImpl(firestore: firestore);
}