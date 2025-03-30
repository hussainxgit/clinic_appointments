import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sms_message.dart';
import '../../domain/entities/sms_response.dart';
import '../models/sms_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final kwtSmsRepositoryProvider = Provider<KwtSmsRepository>((ref) {
  return KwtSmsRepositoryImpl(
    client: http.Client(),
    firestore: FirebaseFirestore.instance,
  );
});

abstract class KwtSmsRepository {
  Future<KwtSmsResponse> sendSms(
    KwtSmsMessage message, {
    required String username,
    required String password,
  });

  Future<SmsRecord> saveSmsRecord(SmsRecord record);
  Future<List<SmsRecord>> getMessageHistory({String? recipient});
}

class KwtSmsRepositoryImpl implements KwtSmsRepository {
  final http.Client client;
  final FirebaseFirestore firestore;
  final String apiUrl = 'https://www.kwtsms.com/API/send/';

  KwtSmsRepositoryImpl({required this.client, required this.firestore});

  @override
  Future<KwtSmsResponse> sendSms(
    KwtSmsMessage message, {
    required String username,
    required String password,
  }) async {
    try {
      final payload = {
        ...message.toMap(),
        'username': username,
        'password': password,
      };

      final response = await client.post(Uri.parse(apiUrl), body: payload);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final jsonResponse = json.decode(response.body);
        return KwtSmsResponse.fromMap(jsonResponse);
      } else {
        return KwtSmsResponse.error(
          'HTTP Error: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      return KwtSmsResponse.error('Failed to send SMS: $e');
    }
  }

  @override
  Future<SmsRecord> saveSmsRecord(SmsRecord record) async {
    try {
      final docRef = firestore.collection('sms_messages').doc();
      final data = record.toMap();

      await docRef.set({...data, 'createdAt': FieldValue.serverTimestamp()});

      return record.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to save SMS record: $e');
    }
  }

  @override
  Future<List<SmsRecord>> getMessageHistory({String? recipient}) async {
    try {
      Query query = firestore
          .collection('sms_messages')
          .orderBy('createdAt', descending: true);

      if (recipient != null) {
        query = query.where('recipient', isEqualTo: recipient);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) =>
                SmsRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get message history: $e');
    }
  }
}
