// lib/features/messaging/presentation/controllers/webhook_controller.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../services/sms_service.dart';

/// Controller to handle SMS delivery status webhooks
///
/// This would typically be used in a backend service, but for completeness,
/// here's how you might implement webhook handling in a Flutter app
class WebhookController {
  final Ref _ref;

  WebhookController(this._ref);

  /// Handle incoming webhook requests
  ///
  /// In a real app, this would be an HTTP endpoint in your backend
  Future<http.Response> handleWebhook(HttpRequest request) async {
    if (request.method != 'POST') {
      return http.Response('Method not allowed', 405);
    }

    try {
      // Read the request body
      final body = await utf8.decoder.bind(request).join();
      final Map<String, dynamic> data = jsonDecode(body);

      // Determine provider based on the endpoint or request path
      final path = request.uri.path;
      String providerId;

      if (path.contains('twilio')) {
        providerId = 'twilio';
      } else if (path.contains('messagebird')) {
        providerId = 'messagebird';
      } else {
        return http.Response('Unknown provider', 400);
      }

      // Process the webhook
      final smsService = _ref.read(smsServiceProvider);
      final result = await smsService.processWebhook(providerId, data);

      if (result.success) {
        return http.Response('OK', 200);
      } else {
        return http.Response('Error: ${result.errorMessage}', 400);
      }
    } catch (e) {
      debugPrint('Error handling webhook: $e');
      return http.Response('Internal server error', 500);
    }
  }
}

/// Factory function to create a WebhookController with the provider ref
WebhookController createWebhookController(Ref ref) {
  return WebhookController(ref);
}
