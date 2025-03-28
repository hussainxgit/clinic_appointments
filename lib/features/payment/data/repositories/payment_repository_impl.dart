import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_record.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'payments';

  PaymentRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<List<PaymentRecord>> getAllPayments() async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => PaymentRecord.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<PaymentRecord>> getPaymentsByAppointment(
    String appointmentId,
  ) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('appointmentId', isEqualTo: appointmentId)
            .get();

    return snapshot.docs
        .map((doc) => PaymentRecord.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<PaymentRecord>> getPaymentsByPatient(String patientId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('patientId', isEqualTo: patientId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => PaymentRecord.fromFirestore(doc))
        .toList();
  }

  @override
  Future<PaymentRecord?> getPaymentById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return doc.exists ? PaymentRecord.fromFirestore(doc) : null;
  }

  @override
  Future<PaymentRecord?> getPaymentByInvoice(String invoiceId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('invoiceId', isEqualTo: invoiceId)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty
        ? PaymentRecord.fromFirestore(snapshot.docs.first)
        : null;
  }

  @override
  Future<PaymentRecord> createPayment(PaymentRecord payment) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = payment.toMap();

    await docRef.set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    final newDoc = await docRef.get();
    return PaymentRecord.fromFirestore(newDoc);
  }

  @override
  Future<PaymentRecord> updatePayment(PaymentRecord payment) async {
    final docRef = _firestore.collection(_collection).doc(payment.id);

    await docRef.update({
      ...payment.toMap(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    final updatedDoc = await docRef.get();
    return PaymentRecord.fromFirestore(updatedDoc);
  }

  @override
  Future<bool> deletePayment(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    return true;
  }

  @override
  Future<List<PaymentRecord>> getPendingPayments() async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('status', isEqualTo: PaymentStatus.pending.toStorageString())
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => PaymentRecord.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> updatePaymentStatus(
    String id,
    PaymentStatus status, {
    String? transactionId,
  }) async {
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
  }
}
