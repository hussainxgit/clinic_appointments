import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_record.dart';

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
    try {
      // First try with gatewayPaymentId
      final snapshot1 = await _firestore
          .collection('payments')
          .where('gatewayPaymentId', isEqualTo: referenceId)
          .get();
      
      if (snapshot1.docs.isNotEmpty) {
        return snapshot1.docs.map((doc) => PaymentRecord.fromMap(doc.data(), doc.id)).toList();
      }
      
      // If not found, try with referenceId
      final snapshot2 = await _firestore
          .collection('payments')
          .where('referenceId', isEqualTo: referenceId)
          .get();
      
      return snapshot2.docs.map((doc) => PaymentRecord.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error in getPaymentsByReference: $e');
      return [];
    }
  }
  
  @override
  Future<PaymentRecord?> getPaymentById(String paymentId) async {
    try {
      // First try as document ID
      try {
        final doc = await _firestore.collection('payments').doc(paymentId).get();
        if (doc.exists) {
          return PaymentRecord.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        print('Error looking up payment by doc ID: $e');
      }
      
      // Try as gatewayPaymentId
      final snapshot1 = await _firestore
          .collection('payments')
          .where('gatewayPaymentId', isEqualTo: paymentId)
          .limit(1)
          .get();
      
      if (snapshot1.docs.isNotEmpty) {
        final doc = snapshot1.docs.first;
        return PaymentRecord.fromMap(doc.data(), doc.id);
      }
      
      // Try as referenceId (which might be appointmentId)
      final snapshot2 = await _firestore
          .collection('payments')
          .where('referenceId', isEqualTo: paymentId)
          .limit(1)
          .get();
      
      if (snapshot2.docs.isNotEmpty) {
        final doc = snapshot2.docs.first;
        return PaymentRecord.fromMap(doc.data(), doc.id);
      }
      
      return null;
    } catch (e) {
      print('Error in getPaymentById: $e');
      return null;
    }
  }
  
  @override
  Future<PaymentRecord> createPaymentRecord(PaymentRecord record) async {
    try {
      final docRef = _firestore.collection('payments').doc();
      final data = record.toMap();
      await docRef.set(data);
      return record.copyWith(id: docRef.id);
    } catch (e) {
      print('Error creating payment record: $e');
      throw Exception('Failed to create payment record: $e');
    }
  }
  
  @override
  Future<PaymentRecord> updatePaymentRecord(PaymentRecord record) async {
    try {
      final data = record.toMap();
      await _firestore.collection('payments').doc(record.id).update(data);
      return record;
    } catch (e) {
      print('Error updating payment record: $e');
      throw Exception('Failed to update payment record: $e');
    }
  }
  
  @override
  Future<bool> deletePaymentRecord(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).delete();
      return true;
    } catch (e) {
      print('Error deleting payment record: $e');
      return false;
    }
  }
}