// lib/features/messaging/data/repositories/sms_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/firebase/firebase_providers.dart';
import '../models/sms_record.dart';

part 'sms_repository.g.dart';

@riverpod
SmsRepository smsRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return SmsRepositoryImpl(firestore: firestore);
}

abstract class SmsRepository {
  Future<List<SmsRecord>> getAllSmsRecords();
  Future<SmsRecord?> getSmsRecordById(String id);
  Future<SmsRecord?> getSmsRecordByMessageId(String messageId);
  Future<List<SmsRecord>> getSmsRecordsByRecipient(String recipient);
  Future<SmsRecord> createSmsRecord(SmsRecord record);
  Future<SmsRecord> updateSmsRecord(SmsRecord record);
  Future<bool> deleteSmsRecord(String id);
  Map<String, dynamic> getConfigMap();
}

class SmsRepositoryImpl implements SmsRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'sms_messages';

  SmsRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Future<List<SmsRecord>> getAllSmsRecords() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs
        .map((doc) => SmsRecord.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<SmsRecord?> getSmsRecordById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return doc.exists ? SmsRecord.fromMap(doc.data()!, doc.id) : null;
  }

  @override
  Future<SmsRecord?> getSmsRecordByMessageId(String messageId) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('messageId', isEqualTo: messageId)
            .limit(1)
            .get();

    return snapshot.docs.isNotEmpty
        ? SmsRecord.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id)
        : null;
  }

  @override
  Future<List<SmsRecord>> getSmsRecordsByRecipient(String recipient) async {
    final snapshot =
        await _firestore
            .collection(_collection)
            .where('to', isEqualTo: recipient)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs
        .map((doc) => SmsRecord.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<SmsRecord> createSmsRecord(SmsRecord record) async {
    final docRef = _firestore.collection(_collection).doc();
    final data = record.toMap();
    await docRef.set(data);
    return record.copyWith(id: docRef.id);
  }

  @override
  Future<SmsRecord> updateSmsRecord(SmsRecord record) async {
    await _firestore
        .collection(_collection)
        .doc(record.id)
        .update(record.toMap());
    return record;
  }

  @override
  Future<bool> deleteSmsRecord(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
    return true;
  }

  @override
  Map<String, dynamic> getConfigMap() {
    return {};
  }
}
