// lib/features/payment/payment_module.dart - Updated to use WhatsApp payment flow
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';
import 'data/payment_repository_provider.dart';
import 'domain/payment_service.dart';
import 'domain/whatsapp_payment_service.dart';
import 'presentation/payment_history_screen.dart';
import 'presentation/payment_settings_screen.dart';
import 'presentation/simplified_payment_screen.dart';
import 'presentation/providers/payment_provider.dart';

class PaymentModule implements FeatureModule {
  @override
  String get moduleId => 'payment';

  @override
  String get moduleName => 'Payments';

  @override
  String? get moduleDescription => 'Process and manage payments via WhatsApp';

  @override
  List<String> get dependsOn => ['appointment', 'messaging']; // Added messaging dependency

  @override
  List<ProviderBase> get providers => [
    paymentRepositoryProvider,
    paymentConfigProvider,
    paymentNotifierProvider,
    whatsAppPaymentServiceProvider, // Added WhatsApp payment service
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/payment/process':
        (_) =>
            const SimplifiedPaymentScreen(), // Using the new simplified screen
    '/payment/history': (_) => const PaymentHistoryScreen(),
    '/payment/settings': (_) => const PaymentSettingsScreen(),
  };

  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      routePath: '/payment/history',
      title: 'Payments',
      icon: Icons.payment_outlined,
      selectedIcon: Icons.payment,
      screen: const PaymentHistoryScreen(),
    ),
  ];

  @override
  Future<void> initialize() async {
    // Initialize payment module
  }
}
