// lib/features/messaging/services/kwt_sms_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/config/kwt_sms_config.dart';
import '../data/repositories/kwt_sms_repository.dart';
import '../domain/entities/sms_message.dart';
import '../domain/entities/sms_response.dart';
import '../data/models/sms_record.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/error_handler.dart';

part 'kwt_sms_service.g.dart';

// Define the repository provider first
final kwtSmsRepositoryProvider = Provider<KwtSmsRepository>((ref) {
  // You need to provide the correct implementation here
  final firestore = ref.watch(firestoreProvider);
  return KwtSmsRepositoryImpl(client: http.Client(), firestore: firestore);
});

// Define a configuration provider for the KWT-SMS API
final kwtSmsConfigProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'username': KwtSmsConfig.apiUsername,
    'password': KwtSmsConfig.apiPassword,
    'sender': KwtSmsConfig.defaultSenderId,
    'defaultLanguage': KwtSmsConfig.englishLanguage,
  };
});

@riverpod
KwtSmsService kwtSmsService(Ref ref) {
  final repository = ref.watch(kwtSmsRepositoryProvider);
  final config = ref.watch(kwtSmsConfigProvider);
  return KwtSmsService(repository: repository, config: config);
}

class KwtSmsService {
  final KwtSmsRepository _repository;
  final Map<String, dynamic> _config;

  KwtSmsService({
    required KwtSmsRepository repository,
    required Map<String, dynamic> config,
  }) : _repository = repository,
       _config = config;

  /// Send an SMS message to a single recipient
  Future<Result<KwtSmsResponse>> sendSms({
    required String phoneNumber,
    required String message,
    String? sender,
    int? languageCode,
    bool isTest = false,
  }) {
    return sendBulkSms(
      phoneNumbers: [phoneNumber],
      message: message,
      sender: sender,
      languageCode: languageCode,
      isTest: isTest,
    );
  }

  /// Send an SMS message to multiple recipients
  Future<Result<KwtSmsResponse>> sendBulkSms({
    required List<String> phoneNumbers,
    required String message,
    String? sender,
    int? languageCode,
    bool isTest = false,
  }) {
    return ErrorHandler.guardAsync(() async {
      if (phoneNumbers.isEmpty) {
        throw 'At least one phone number is required';
      }

      if (message.isEmpty) {
        throw 'Message content cannot be empty';
      }

      final formattedNumbers = KwtSmsMessage.formatMobileNumbers(phoneNumbers);

      // Create the message object
      final smsMessage = KwtSmsMessage(
        mobile: formattedNumbers,
        message: message,
        sender: sender ?? _config['sender'],
        languageCode: languageCode ?? _config['defaultLanguage'],
        isTest: isTest,
      );

      // Create a pending record for the message
      final record = SmsRecord(
        recipient: formattedNumbers,
        message: message,
        sender: smsMessage.sender,
        status: 'pending',
        metadata: {
          'languageCode': smsMessage.languageCode,
          'isTest': smsMessage.isTest,
          'recipientCount': phoneNumbers.length,
        },
      );

      // Save the record first
      final savedRecordResult = await _repository.saveSmsRecord(record);
      if (savedRecordResult.isFailure) {
        throw 'Failed to save SMS record: ${savedRecordResult.error}';
      }

      final savedRecord = savedRecordResult.data;

      // Send the SMS
      final response = await _repository.sendSms(
        smsMessage,
        username: _config['username'],
        password: _config['password'],
      );

      if (response.isFailure) {
        // Update the record with failed status
        await _repository.saveSmsRecord(
          savedRecord.copyWith(
            status: 'failed',
            metadata: {
              ...savedRecord.metadata ?? {},
              'error': response.error,
              'timestamp': DateTime.now().toIso8601String(),
            },
          ),
        );

        throw response.error;
      }

      // Update the record with the result
      await _repository.saveSmsRecord(
        savedRecord.copyWith(
          status: 'sent',
          messageId: response.data.messageId,
          metadata: {
            ...savedRecord.metadata ?? {},
            'response': {
              'isSuccess': response.data.isSuccess,
              'numbersProcessed': response.data.numbersProcessed,
              'pointsCharged': response.data.pointsCharged,
              'balanceAfter': response.data.balanceAfter,
              'timestamp': response.data.timestamp,
            },
          },
        ),
      );

      return response.data;
    }, 'sending SMS message');
  }

  /// Get message history for a specific recipient or all messages
  Future<Result<List<SmsRecord>>> getMessageHistory({String? recipient}) {
    return ErrorHandler.guardAsync(() async {
      final recordsResult = await _repository.getMessageHistory(
        recipient: recipient,
      );

      if (recordsResult.isFailure) {
        throw recordsResult.error;
      }

      return recordsResult.data;
    }, 'getting message history');
  }
}
