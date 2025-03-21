// lib/features/messaging/domain/services/sms_service.dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/sms_record.dart';
import '../data/repositories/sms_repository.dart';
import '../domain/entities/sms_message.dart';
import '../domain/entities/sms_response.dart';
import '../domain/interfaces/sms_provider.dart';

part 'sms_service.g.dart';

// SMS configuration provider
final smsConfigProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'defaultProvider': 'twilio',
    'providers': {
      'twilio': {
        'accountSid': Platform.environment['TWILIO_ACCOUNT_SID'] ?? '',
        'authToken': Platform.environment['TWILIO_AUTH_TOKEN'] ?? '',
        'defaultFrom': '+19896137314',
      },
    },
  };
});

@riverpod
SmsService smsService(Ref ref) {
  final smsRepository = ref.watch(smsRepositoryProvider);
  final config = ref.watch(smsConfigProvider);
  return SmsService(repository: smsRepository, config: config);
}

class SmsService {
  final SmsRepository _repository;
  final Map<String, SmsProvider> _providers = {};
  final String _defaultProviderId;

  SmsService({
    required SmsRepository repository,
    required Map<String, dynamic> config,
  }) : _repository = repository,
       _defaultProviderId = config['defaultProvider'] ?? 'twilio' {
    // Register providers here
    // This would be done by the feature module initialization
  }

  /// Register an SMS provider
  void registerProvider(SmsProvider provider, {Map<String, dynamic>? config}) {
    _providers[provider.providerId] = provider;

    // Initialize provider if config is provided
    if (config != null) {
      provider.initialize(config);
    } else {
      // Try to use config from global settings
      final providersConfig = _getProvidersConfig();
      if (providersConfig.containsKey(provider.providerId)) {
        provider.initialize(providersConfig[provider.providerId]!);
      }
    }
  }

  /// Get all registered providers
  List<SmsProvider> getProviders() {
    return _providers.values.toList();
  }

  /// Send an SMS message using the specified provider
  Future<SmsResponse> sendSms(SmsMessage message, {String? providerId}) async {
    final useProviderId = providerId ?? _defaultProviderId;

    // Get the provider
    final provider = _providers[useProviderId];
    if (provider == null) {
      return SmsResponse.error(
        errorMessage: 'SMS provider $useProviderId not found or not registered',
      );
    }

    try {
      // Create pending record
      final record = SmsRecord(
        id: '',
        providerId: useProviderId,
        to: message.to,
        from: message.from.isNotEmpty ? message.from : '',
        body: message.body,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final savedRecord = await _repository.createSmsRecord(record);

      // Send SMS
      final response = await provider.sendSms(message);

      // Update record with result
      final updatedRecord = savedRecord.copyWith(
        messageId: response.messageId,
        status: _mapStatusToString(response.status),
        errorMessage: response.errorMessage,
        updatedAt: DateTime.now(),
        metadata: response.providerResponse,
      );

      await _repository.updateSmsRecord(updatedRecord);

      return response;
    } catch (e) {
      return SmsResponse.error(
        errorMessage: 'Error in SMS service: ${e.toString()}',
      );
    }
  }

  /// Check the status of a sent message
  Future<SmsResponse> checkMessageStatus(String messageId) async {
    try {
      // Find message record
      final record = await _repository.getSmsRecordByMessageId(messageId);
      if (record == null) {
        return SmsResponse.error(
          errorMessage: 'Message with ID $messageId not found',
        );
      }

      // Get the provider
      final provider = _providers[record.providerId];
      if (provider == null) {
        return SmsResponse.error(
          errorMessage: 'Provider ${record.providerId} not found',
        );
      }

      // Check status
      final response = await provider.checkStatus(messageId);

      // Update record
      final updatedRecord = record.copyWith(
        status: _mapStatusToString(response.status),
        errorMessage: response.errorMessage,
        updatedAt: DateTime.now(),
        metadata: response.providerResponse,
      );

      await _repository.updateSmsRecord(updatedRecord);

      return response;
    } catch (e) {
      return SmsResponse.error(
        errorMessage: 'Error checking message status: ${e.toString()}',
      );
    }
  }

  /// Process webhook callback from provider
  Future<SmsResponse> processWebhook(
    String providerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final provider = _providers[providerId];
      if (provider == null) {
        return SmsResponse.error(
          errorMessage: 'Provider $providerId not found',
        );
      }

      if (!provider.validateWebhook(data)) {
        return SmsResponse.error(errorMessage: 'Invalid webhook data');
      }

      // Extract message ID from webhook data (implementation depends on provider)
      final messageId = _extractMessageId(providerId, data);
      if (messageId == null) {
        return SmsResponse.error(
          errorMessage: 'Could not extract message ID from webhook data',
        );
      }

      // Extract status
      final status = provider.extractStatusFromWebhook(data);

      // Update record if found
      final record = await _repository.getSmsRecordByMessageId(messageId);
      if (record != null) {
        final updatedRecord = record.copyWith(
          status: _mapStatusToString(status),
          updatedAt: DateTime.now(),
          metadata: {...?record.metadata, 'webhook': data},
        );

        await _repository.updateSmsRecord(updatedRecord);
      }

      return SmsResponse.success(
        messageId: messageId,
        status: status,
        providerResponse: data,
      );
    } catch (e) {
      return SmsResponse.error(
        errorMessage: 'Error processing webhook: ${e.toString()}',
      );
    }
  }

  /// Get message history for a recipient
  Future<List<SmsRecord>> getMessageHistory(String recipient) async {
    try {
      return await _repository.getSmsRecordsByRecipient(recipient);
    } catch (e) {
      print('Error getting message history: $e');
      return [];
    }
  }

  // Helper methods
  Map<String, Map<String, dynamic>> _getProvidersConfig() {
    final config = _repository.getConfigMap();
    return (config['providers'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as Map<String, dynamic>),
        ) ??
        {};
  }

  String _mapStatusToString(SmsDeliveryStatus status) {
    switch (status) {
      case SmsDeliveryStatus.sent:
        return 'sent';
      case SmsDeliveryStatus.delivered:
        return 'delivered';
      case SmsDeliveryStatus.failed:
        return 'failed';
      case SmsDeliveryStatus.undelivered:
        return 'undelivered';
      case SmsDeliveryStatus.queued:
        return 'queued';
      case SmsDeliveryStatus.unknown:
        return 'unknown';
    }
  }

  String? _extractMessageId(String providerId, Map<String, dynamic> data) {
    switch (providerId) {
      case 'twilio':
        return data['MessageSid'] as String?;
      // Add cases for other providers
      default:
        return null;
    }
  }
}
