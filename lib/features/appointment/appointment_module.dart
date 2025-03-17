// lib/features/appointment/appointment_module.dart
import 'package:clinic_appointments/features/appointment/data/appointment_providers.dart';
import 'package:clinic_appointments/features/appointment/presentation/screens/appointment_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';
import 'presentation/providers/appointment_notifier.dart';
import 'presentation/screens/appointment_payment_screen.dart';
import 'presentation/screens/appointment_screens.dart';
import 'presentation/screens/appointment_form_screen.dart';

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
  List<ProviderBase> get providers => [
    appointmentNotifierProvider,
    appointmentRepositoryProvider,
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/appointment/list': (_) => const AppointmentsScreen(),
    '/appointment/create': (_) => const AppointmentFormScreen(),
    '/appointment/edit': (_) => const AppointmentFormScreen(isEditing: true),
    '/appointment/details': (_) => const AppointmentDetailsScreen(),
    '/appointment/payment': (_) => const AppointmentPaymentScreen(),
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
    // No additional initialization needed
  }
}
