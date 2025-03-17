// lib/features/payment/data/payment_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/firebase/firebase_providers.dart';
import 'repository/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return PaymentRepositoryImpl(firestore: firestore);
});