// lib/features/messaging/data/repositories/kwt_sms_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/sms_message.dart';
import '../../domain/entities/sms_response.dart';
import '../models/sms_record.dart';

abstract class KwtSmsRepository {
  Future<Result<KwtSmsResponse>> sendSms(
    KwtSmsMessage message, {
    required String username,
    required String password,
  });

  Future<Result<SmsRecord>> saveSmsRecord(SmsRecord record);
  Future<Result<List<SmsRecord>>> getMessageHistory({String? recipient});
}

class KwtSmsRepositoryImpl implements KwtSmsRepository {
  final http.Client client;
  final FirebaseFirestore firestore;
  final String apiUrl = 'https://www.kwtsms.com/API/send/';

  KwtSmsRepositoryImpl({required this.client, required this.firestore});

  @override
  Future<Result<KwtSmsResponse>> sendSms(
    KwtSmsMessage message, {
    required String username,
    required String password,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final payload = {
        ...message.toMap(),
        'username': username,
        'password': password,
      };

      final response = await client.post(Uri.parse(apiUrl), body: payload);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = response.body.trim();

        // Check if the response is in the format "OK:messageId:numbers:charged:balance:timestamp"
        if (responseBody.startsWith('OK:')) {
          final parts = responseBody.split(':');
          if (parts.length >= 6) {
            return KwtSmsResponse(
              isSuccess: true,
              messageId: parts[1],
              numbersProcessed: int.tryParse(parts[2]),
              pointsCharged: int.tryParse(parts[3]),
              balanceAfter: int.tryParse(parts[4]),
              timestamp: int.tryParse(parts[5]),
            );
          }
        }

        // Try parsing as JSON if it's not in the string format
        try {
          final jsonResponse = json.decode(responseBody);
          return KwtSmsResponse.fromMap(jsonResponse);
        } catch (jsonError) {
          // If we can't parse as JSON and it starts with "OK", consider it a success
          if (responseBody.startsWith('OK')) {
            return KwtSmsResponse(
              isSuccess: true,
              messageId: responseBody.substring(3).trim(),
            );
          }

          // Otherwise, return the error message
          return KwtSmsResponse.error(
            'Failed to parse API response: $responseBody',
          );
        }
      } else {
        return KwtSmsResponse.error(
          'HTTP Error: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    }, 'sending SMS');
  }

  @override
  Future<Result<SmsRecord>> saveSmsRecord(SmsRecord record) async {
    return ErrorHandler.guardAsync(() async {
      final docRef = firestore.collection('sms_messages').doc();
      final data = record.toMap();

      await docRef.set({...data, 'createdAt': FieldValue.serverTimestamp()});

      return record.copyWith(id: docRef.id);
    }, 'saving SMS record');
  }

  @override
  Future<Result<List<SmsRecord>>> getMessageHistory({String? recipient}) async {
    return ErrorHandler.guardAsync(() async {
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
    }, 'getting message history');
  }
}
