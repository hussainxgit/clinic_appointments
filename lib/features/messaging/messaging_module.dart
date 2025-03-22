// lib/features/messaging/messaging_module.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';
import 'data/providers/twilio_provider.dart';
import 'data/repositories/sms_repository.dart';
import 'presentation/screen/messaging_history_screen.dart';
import 'presentation/screen/messaging_screen.dart';
import 'presentation/screen/template_message_screen.dart';
import 'services/sms_service.dart';

class MessagingModule implements FeatureModule {
  @override
  String get moduleId => 'messaging';

  @override
  String get moduleName => 'Messaging';

  @override
  String? get moduleDescription => 'SMS messaging functionality';

  @override
  List<String> get dependsOn => [];

  @override
  List<ProviderBase> get providers => [
    smsRepositoryProvider,
    smsServiceProvider,
    smsConfigProvider,
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/messaging': (_) => const MessagingScreen(),
    '/messaging/template': (_) => const TemplateMessageScreen(),
    '/messaging/history': (_) => const MessagingHistoryScreen(),
  };

  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      routePath: '/messaging',
      title: 'Messages',
      icon: Icons.message_outlined,
      selectedIcon: Icons.message,
      screen: const MessagingScreen(),
    ),
    NavigationItem(
      routePath: '/messaging/template',
      title: 'Templates',
      icon: Icons.format_quote_outlined,
      selectedIcon: Icons.format_quote,
      screen: const TemplateMessageScreen(),
    ),
  ];

  @override
  Future<void> initialize() async {
    // Register SMS providers
    final twilio = TwilioProvider();

    // Access providers directly for initialization
    // In a real app, this would be done more elegantly
    final container = ProviderContainer();
    final smsService = container.read(smsServiceProvider);
    final config = container.read(smsConfigProvider);

    // Register the Twilio provider
    final twilioConfig =
        (config['providers'] as Map<String, dynamic>)['twilio'];
    smsService.registerProvider(twilio, config: twilioConfig);
  }
}
