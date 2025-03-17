// lib/features/payment/data/repository/payment_repository.dart
import 'package:clinic_appointments/features/payment/data/models/payment_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PaymentRepository {
  Future<List<PaymentRecord>> getAllPayments();
  Future<List<PaymentRecord>> getPaymentsByPatient(String patientId);
  Future<List<PaymentRecord>> getPaymentsByReference(String referenceId);
  Future<PaymentRecord?> getPaymentById(String paymentId);
  Future<PaymentRecord> createPaymentRecord(PaymentRecord record);
  Future<PaymentRecord> updatePaymentRecord(PaymentRecord record);
  Future<bool> deletePaymentRecord(String paymentId);
}

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  
  PaymentRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;
  
  @override
  Future<List<PaymentRecord>> getAllPayments() async {
    final snapshot = await _firestore.collection('payments').get();
    return snapshot.docs.map((doc) => PaymentRecord.fromMap(doc.data(), doc.id)).toList();
  }
  
  @override
  Future<List<PaymentRecord>> getPaymentsByPatient(String patientId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('patientId', isEqualTo: patientId)
        .get();
    
    return snapshot.docs.map((doc) => PaymentRecord.fromMap(doc.data(), doc.id)).toList();
  }
  
  @override
  Future<List<PaymentRecord>> getPaymentsByReference(String referenceId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('referenceId', isEqualTo: referenceId)
        .get();
    
    return snapshot.docs.map((doc) => PaymentRecord.fromMap(doc.data(), doc.id)).toList();
  }
  
  @override
  Future<PaymentRecord?> getPaymentById(String paymentId) async {
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (!doc.exists) {
      return null;
    }
    return PaymentRecord.fromMap(doc.data()!, doc.id);
  }
  
  @override
  Future<PaymentRecord> createPaymentRecord(PaymentRecord record) async {
    final docRef = _firestore.collection('payments').doc();
    final data = record.toMap();
    await docRef.set(data);
    return record.copyWith(id: docRef.id);
  }
  
  @override
  Future<PaymentRecord> updatePaymentRecord(PaymentRecord record) async {
    final data = record.toMap();
    await _firestore.collection('payments').doc(record.id).update(data);
    return record;
  }
  
  @override
  Future<bool> deletePaymentRecord(String paymentId) async {
    await _firestore.collection('payments').doc(paymentId).delete();
    return true;
  }
}

