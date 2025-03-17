// lib/features/payment/payment_module.dart
import 'package:clinic_appointments/features/payment/data/payment_repository_provider.dart';
import 'package:clinic_appointments/features/payment/domain/payment_service.dart';
import 'package:clinic_appointments/features/payment/presentation/payment_history_screen.dart';
import 'package:clinic_appointments/features/payment/presentation/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';


class PaymentModule implements FeatureModule {
  @override
  String get moduleId => 'payment';

  @override
  String get moduleName => 'Payments';

  @override
  String? get moduleDescription => 'Process and manage payments';

  @override
  List<String> get dependsOn => ['appointment']; // Depends on appointments module

  @override
  List<ProviderBase> get providers => [
    paymentServiceProvider,
    paymentRepositoryProvider,
    paymentConfigProvider,
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/payment/process': (_) => const PaymentScreen(),
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
    // Initialize payment module
  }
}