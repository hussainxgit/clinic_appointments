import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/config/kwt_sms_config.dart';
import '../data/repositories/kwt_sms_repository.dart';
import '../domain/entities/sms_message.dart';
import '../domain/entities/sms_response.dart';
import '../data/models/sms_record.dart';
import '../../../../core/utils/result.dart';

part 'kwt_sms_service.g.dart';

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
  }) async {
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
  }) async {
    try {
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
      final savedRecord = await _repository.saveSmsRecord(record);

      // Send the SMS
      final response = await _repository.sendSms(
        smsMessage,
        username: _config['username'],
        password: _config['password'],
      );

      // Update the record with the result
      await _repository.saveSmsRecord(
        savedRecord.copyWith(
          status: response.isSuccess ? 'sent' : 'failed',
          messageId: response.messageId,
          metadata: {
            ...savedRecord.metadata ?? {},
            'response': {
              'isSuccess': response.isSuccess,
              'numbersProcessed': response.numbersProcessed,
              'pointsCharged': response.pointsCharged,
              'balanceAfter': response.balanceAfter,
              'timestamp': response.timestamp,
              'errorMessage': response.errorMessage,
            },
          },
        ),
      );

      if (response.isSuccess) {
        return Result.success(response);
      } else {
        return Result.failure(response.errorMessage ?? 'Failed to send SMS');
      }
    } catch (e) {
      return Result.failure('Error in SMS service: $e');
    }
  }

  /// Get message history for a specific recipient or all messages
  Future<Result<List<SmsRecord>>> getMessageHistory({String? recipient}) async {
    try {
      final records = await _repository.getMessageHistory(recipient: recipient);
      return Result.success(records);
    } catch (e) {
      return Result.failure('Failed to get message history: $e');
    }
  }
}
