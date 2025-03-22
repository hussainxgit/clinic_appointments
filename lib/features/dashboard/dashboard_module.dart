import 'package:clinic_appointments/core/module/feature_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/dashboard_screen.dart';

class DashboardModule extends FeatureModule {
  @override
  String get moduleId => 'dashboard';

  @override
  String get moduleName => 'Dashboard';

  @override
  String? get moduleDescription =>
      'Overview of clinic appointments, patients, and doctors';

  @override
  List<String> get dependsOn => ['appointment_slot', 'appointment', 'patient', 'doctor'];

  @override
  List<ProviderBase> get providers => [
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/dashboard/': (_) => const DashboardScreen(),
    
  };

  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      routePath: '/dashboard/',
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      screen: const DashboardScreen(),
    ),
  ];

  @override
  Future<void> initialize() async {}
}
