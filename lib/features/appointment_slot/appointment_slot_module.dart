// lib/features/appointment_slot/appointment_slot_module.dart
import 'package:clinic_appointments/features/appointment_slot/data/appointment_slot_providers.dart';
import 'package:clinic_appointments/features/appointment_slot/presentation/pages/slot_management_page.dart';
import 'package:clinic_appointments/features/appointment_slot/presentation/providers/appointment_slot_notifier.dart';
import 'package:clinic_appointments/features/appointment_slot/presentation/screens/appointment_slot_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';
import 'presentation/screens/appointment_slot_form_screen.dart';
import 'presentation/screens/appointment_slots_screen.dart';

class AppointmentSlotModule implements FeatureModule {
  @override
  String get moduleId => 'appointment_slot';

  @override
  String get moduleName => 'Appointment Slots';

  @override
  String? get moduleDescription => 'Manage doctor appointment slots';

  @override
  List<String> get dependsOn => ['doctor', 'patient', 'appointment'];

  @override
  List<ProviderBase> get providers => [
    appointmentSlotNotifierProvider,
    appointmentSlotRepositoryProvider,
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
    '/appointment-slot/list': (_) => const AppointmentSlotsScreen(),
    '/appointment-slot/add': (_) => const SlotManagementPage(),
    '/appointment-slot/edit': (_) => const SlotManagementPage(),
    '/appointment-slot/details': (_) => const AppointmentSlotDetailsScreen(),
  };

  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      routePath: '/appointment-slot/list',
      title: 'Slots',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      screen: const AppointmentSlotsScreen(),
    ),
  ];

  @override
  Future<void> initialize() async {
    // No initialization needed for Riverpod
  }
}
