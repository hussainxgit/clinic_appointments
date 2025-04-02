// lib/features/payment/data/repositories/payment_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../models/payment_record.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'payments';

  PaymentRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<Result<List<PaymentRecord>>> getAllPayments() async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await _firestore
              .collection(_collection)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();
    }, 'fetching all payments');
  }

  @override
  Future<Result<List<PaymentRecord>>> getPaymentsByAppointment(
    String appointmentId,
  ) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('appointmentId', isEqualTo: appointmentId)
              .get();

      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();
    }, 'fetching payments by appointment');
  }

  @override
  Future<Result<List<PaymentRecord>>> getPaymentsByPatient(
    String patientId,
  ) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('patientId', isEqualTo: patientId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();
    }, 'fetching payments by patient');
  }

  @override
  Future<Result<PaymentRecord?>> getPaymentById(String id) async {
    return ErrorHandler.guardAsync(() async {
      final doc = await _firestore.collection(_collection).doc(id).get();
      return doc.exists ? PaymentRecord.fromFirestore(doc) : null;
    }, 'fetching payment by ID');
  }

  @override
  Future<Result<PaymentRecord?>> getPaymentByInvoice(String invoiceId) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where('invoiceId', isEqualTo: invoiceId)
              .limit(1)
              .get();

      return snapshot.docs.isNotEmpty
          ? PaymentRecord.fromFirestore(snapshot.docs.first)
          : null;
    }, 'fetching payment by invoice');
  }

  @override
  Future<Result<PaymentRecord>> createPayment(PaymentRecord payment) async {
    return ErrorHandler.guardAsync(() async {
      final docRef = _firestore.collection(_collection).doc();
      final data = payment.toMap();

      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final newDoc = await docRef.get();
      return PaymentRecord.fromFirestore(newDoc);
    }, 'creating payment');
  }

  @override
  Future<Result<PaymentRecord>> updatePayment(PaymentRecord payment) async {
    return ErrorHandler.guardAsync(() async {
      final docRef = _firestore.collection(_collection).doc(payment.id);

      await docRef.update({
        ...payment.toMap(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      final updatedDoc = await docRef.get();
      return PaymentRecord.fromFirestore(updatedDoc);
    }, 'updating payment');
  }

  @override
  Future<Result<bool>> deletePayment(String id) async {
    return ErrorHandler.guardAsync(() async {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    }, 'deleting payment');
  }

  @override
  Future<Result<List<PaymentRecord>>> getPendingPayments() async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await _firestore
              .collection(_collection)
              .where(
                'status',
                isEqualTo: PaymentStatus.pending.toStorageString(),
              )
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => PaymentRecord.fromFirestore(doc))
          .toList();
    }, 'fetching pending payments');
  }

  @override
  Future<Result<void>> updatePaymentStatus(
    String id,
    PaymentStatus status, {
    String? transactionId,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final updateData = <String, dynamic>{
        'status': status.toStorageString(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (status == PaymentStatus.successful) {
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }

      if (transactionId != null) {
        updateData['transactionId'] = transactionId;
      }

      await _firestore.collection(_collection).doc(id).update(updateData);
    }, 'updating payment status');
  }
}
