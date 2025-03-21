// lib/features/messaging/data/providers/twilio_provider.dart
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
  }

  @override
  Future<SmsResponse> sendSms(SmsMessage message) async {
    if (!_isInitialized) {
      return SmsResponse.error(errorMessage: 'Twilio provider not initialized');
    }

    final from = message.from.isNotEmpty ? message.from : _defaultFrom;

    try {
      final url = '$_baseUrl$_accountSid/Messages.json';

      // Prepare request body
      final body = {'To': message.to, 'From': from, 'Body': message.body};

      // Check if this is a templated message for WhatsApp
      if (message.metadata != null &&
          message.metadata!.containsKey('isWhatsApp') &&
          message.metadata!['isWhatsApp'] == true) {
        // For WhatsApp, the To field needs 'whatsapp:' prefix
        body['To'] = 'whatsapp:${message.to}';
        body['From'] = 'whatsapp:$from';

        // If template is specified
        if (message.metadata!.containsKey('templateId')) {
          final templateId = message.metadata!['templateId'];
          // Add template SID if available
          if (message.metadata!.containsKey(templateId)) {
            body['ContentSid'] = message.metadata![templateId];
          }
        }
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic ${_getAuthHeader()}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SmsResponse.success(
          messageId: responseData['sid'],
          status: _mapTwilioStatus(responseData['status']),
          providerResponse: responseData,
        );
      } else {
        return SmsResponse.error(
          errorMessage: responseData['message'] ?? 'Failed to send SMS',
          providerResponse: responseData,
        );
      }
    } catch (e) {
      return SmsResponse.error(
        errorMessage: 'Error sending SMS: ${e.toString()}',
      );
    }
  }

  @override
  Future<SmsResponse> checkStatus(String messageId) async {
    if (!_isInitialized) {
      return SmsResponse.error(errorMessage: 'Twilio provider not initialized');
    }

    try {
      final url = '$_baseUrl$_accountSid/Messages/$messageId.json';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Basic ${_getAuthHeader()}'},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SmsResponse.success(
          messageId: messageId,
          status: _mapTwilioStatus(responseData['status']),
          providerResponse: responseData,
        );
      } else {
        return SmsResponse.error(
          errorMessage: responseData['message'] ?? 'Failed to check SMS status',
          providerResponse: responseData,
        );
      }
    } catch (e) {
      return SmsResponse.error(
        errorMessage: 'Error checking SMS status: ${e.toString()}',
      );
    }
  }

  @override
  bool validateWebhook(Map<String, dynamic> data) {
    if (!_isInitialized) return false;

    // For basic validation, just check if the MessageSid is present
    if (!data.containsKey('MessageSid')) return false;

    // For more secure validation with Twilio's signatures, use the following:
    // 1. Get the 'X-Twilio-Signature' from the headers
    // 2. Validate using the algorithm described in Twilio's docs
    // This would require the full request URL and headers

    return true;
  }

  @override
  SmsDeliveryStatus extractStatusFromWebhook(Map<String, dynamic> data) {
    if (!data.containsKey('MessageStatus')) {
      return SmsDeliveryStatus.unknown;
    }

    return _mapTwilioStatus(data['MessageStatus']);
  }

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
}
