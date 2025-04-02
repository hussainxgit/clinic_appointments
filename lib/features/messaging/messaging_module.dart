// lib/features/messaging/messaging_module.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/module/feature_module.dart';
import '../../core/firebase/firebase_providers.dart';
import 'data/repositories/kwt_sms_repository.dart';
import 'presentation/screens/messaging_screen.dart';
import 'presentation/screens/message_form_screen.dart';
import 'services/kwt_sms_service.dart';
import 'presentation/providers/messaging_notifier.dart';

// Define repository provider here to avoid circular dependencies
final kwtSmsRepositoryProvider = Provider<KwtSmsRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return KwtSmsRepositoryImpl(
    client: http.Client(),
    firestore: firestore,
  );
});

class MessagingModule implements FeatureModule {
  @override
  String get moduleId => 'messaging';

  @override
  String get moduleName => 'Messaging';

  @override
  String? get moduleDescription => 'Send SMS messages to patients and contacts';

  @override
  List<String> get dependsOn => ['patient'];

  @override
  List<ProviderBase> get providers => [
    kwtSmsRepositoryProvider,
    kwtSmsServiceProvider,
    kwtSmsConfigProvider,
    messagingProvider,
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/messaging': (_) => const MessagingScreen(),
    '/messaging/new': (_) => const MessageFormScreen(),
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
  ];

  @override
  Future<void> initialize() async {
    // No initialization required
  }
}