import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';
import 'domain/providers.dart';
import 'presentation/screens/payment_history_screen.dart';
import 'presentation/screens/payment_link_screen.dart';

class PaymentModule implements FeatureModule {
  @override
  String get moduleId => 'payment';

  @override
  String get moduleName => 'Payments';

  @override
  String? get moduleDescription => 'Process and manage payments via WhatsApp';

  @override
  List<String> get dependsOn => ['appointment', 'messaging'];

  @override
  List<ProviderBase> get providers => [
    paymentRepositoryProvider,
    paymentServiceProvider,
    paymentHistoryProvider,
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/payment/send': (_) => const PaymentLinkScreen(),
    '/payment/history': (_) => const PaymentHistoryScreen(),
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
    // No initialization needed
  }
}
