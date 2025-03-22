// Update lib/features/messaging/data/providers/twilio_provider.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/interfaces/sms_provider.dart';
import '../../domain/entities/sms_message.dart';
import '../../domain/entities/sms_response.dart';

class TwilioProvider implements SmsProvider {
  late String _accountSid;
  late String _authToken;
  late String _defaultFrom;
  bool _isInitialized = false;
  final String _baseUrl = 'https://api.twilio.com/2010-04-01/Accounts/';

  @override
  String get providerId => 'twilio';

  @override
  String get displayName => 'Twilio';

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    if (!config.containsKey('accountSid')) {
      throw Exception('Twilio account SID is required');
    }
    if (!config.containsKey('authToken')) {
      throw Exception('Twilio auth token is required');
    }
    if (!config.containsKey('defaultFrom')) {
      throw Exception('Twilio default from number is required');
    }

    _accountSid = config['accountSid'];
    _authToken = config['authToken'];
    _defaultFrom = config['defaultFrom'];
    _isInitialized = true;

    print('Twilio initialized with SID: ${_maskSid(_accountSid)}');
  }

  String _maskSid(String sid) {
    if (sid.length > 8) {
      return '${sid.substring(0, 4)}...${sid.substring(sid.length - 4)}';
    }
    return sid;
  }

  @override
  Future<SmsResponse> sendSms(SmsMessage message) async {
    if (!_isInitialized) {
      return SmsResponse.error(errorMessage: 'Twilio provider not initialized');
    }

    final from = message.from.isNotEmpty ? message.from : _defaultFrom;

    try {
      final url = '$_baseUrl$_accountSid/Messages.json';

      Map<String, dynamic> body = {};

      // Check if this is a WhatsApp template message
      if (message.metadata != null &&
          message.metadata!.containsKey('isWhatsApp') &&
          message.metadata!['isWhatsApp'] == true) {
        // For WhatsApp templates
        body = {'To': 'whatsapp:${message.to}', 'From': 'whatsapp:$from'};

        // If we have a content_sid for the template
        if (message.metadata!.containsKey('contentSid')) {
          body['ContentSid'] = message.metadata!['contentSid'];

          // If we have variables for the template
          if (message.metadata!.containsKey('variables')) {
            body['ContentVariables'] = jsonEncode(
              message.metadata!['variables'],
            );
          }
        } else {
          // If no template, just use the body
          body['Body'] = message.body;
        }
      } else {
        // Regular SMS
        body = {'To': message.to, 'From': from, 'Body': message.body};
      }

      print('Sending Twilio request to: $url');
      print('Request body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic ${_getAuthHeader()}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      print('Twilio response status: ${response.statusCode}');
      print('Twilio response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return SmsResponse.success(
          messageId: responseData['sid'],
          status: _mapTwilioStatus(responseData['status']),
          providerResponse: responseData,
        );
      } else {
        String errorMessage = 'Failed to send message';
        try {
          final responseData = jsonDecode(response.body);
          errorMessage =
              responseData['message'] ??
              responseData['error_message'] ??
              'Failed to send message';
        } catch (e) {
          errorMessage = 'Failed to send message: ${response.body}';
        }
        return SmsResponse.error(errorMessage: errorMessage);
      }
    } catch (e) {
      print('Error sending via Twilio: $e');
      return SmsResponse.error(errorMessage: 'Error sending: $e');
    }
  }
  // Rest of your methods (checkStatus, validateWebhook, etc.) remain the same

  String _getAuthHeader() {
    final credentials = '$_accountSid:$_authToken';
    return base64Encode(utf8.encode(credentials));
  }

  SmsDeliveryStatus _mapTwilioStatus(String? twilioStatus) {
    switch (twilioStatus) {
      case 'sent':
        return SmsDeliveryStatus.sent;
      case 'delivered':
        return SmsDeliveryStatus.delivered;
      case 'failed':
        return SmsDeliveryStatus.failed;
      case 'undelivered':
        return SmsDeliveryStatus.undelivered;
      case 'queued':
        return SmsDeliveryStatus.queued;
      default:
        return SmsDeliveryStatus.unknown;
    }
  }

  @override
  Future<SmsResponse> checkStatus(String messageId) {
    // TODO: implement checkStatus
    throw UnimplementedError();
  }

  @override
  SmsDeliveryStatus extractStatusFromWebhook(Map<String, dynamic> data) {
    // TODO: implement extractStatusFromWebhook
    throw UnimplementedError();
  }

  @override
  bool validateWebhook(Map<String, dynamic> data) {
    // TODO: implement validateWebhook
    throw UnimplementedError();
  }
}
