// lib/features/appointment/appointment_module.dart
import 'package:flutter/material.dart';

import 'package:provider/single_child_widget.dart';

import '../../core/module/feature_module.dart';

import 'presentation/screens/appointment_screens.dart';

class AppointmentModule implements FeatureModule {
  @override
  String get moduleId => 'appointment';

  @override
  String get moduleName => 'Appointments';

  @override
  String? get moduleDescription => 'Manage patient appointments';

  @override
  List<String> get dependsOn => ['doctor', 'patient', 'appointment_slot'];

  @override
  List<SingleChildWidget> get providers => []; // No longer needed with Riverpod

  @override
  Map<String, WidgetBuilder> get routes => {
    '/appointment/list': (_) => const AppointmentsScreen(),
    // '/appointment/details': (_) => const AppointmentDetailsScreen(),
    // '/appointment/create': (_) => const AppointmentFormScreen(isEditing: false),
    // '/appointment/edit': (_) => const AppointmentFormScreen(isEditing: true),
  };

  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      routePath: '/appointment/list',
      title: 'Appointments',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
      screen: const AppointmentsScreen(),
    ),
  ];

  @override
  Future<void> initialize() async {
    // No initialization needed for Riverpod
    // You can initialize any services or repositories here if needed
  }
}
