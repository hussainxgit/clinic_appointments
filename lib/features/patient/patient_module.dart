// lib/features/patient/patient_module.dart
import 'package:clinic_appointments/features/patient/data/patient_providers.dart';
import 'package:clinic_appointments/features/patient/presentation/providers/patient_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';
import 'presentation/screens/patient_details_screen.dart';
import 'presentation/screens/patient_form_screen.dart';
import 'presentation/screens/patient_screen.dart';

class PatientModule implements FeatureModule {
  @override
  String get moduleId => 'patient';

  @override
  String get moduleName => 'Patient Management';

  @override
  String? get moduleDescription =>
      'Manage clinic patients and their information';

  @override
  List<String> get dependsOn => ['appointment_slot', 'appointment', 'doctor'];

  @override
  List<ProviderBase> get providers => [
    patientNotifierProvider,
    patientRepositoryProvider,
  ]; 

  @override
  Map<String, WidgetBuilder> get routes => {
    '/patient/list': (_) => const PatientsScreen(),
    '/patient/details': (_) => const PatientDetailsScreen(),
    '/patient/add': (_) => const PatientFormScreen(isEditing: false),
    '/patient/edit': (_) => const PatientFormScreen(isEditing: true),
  };

  @override
  List<NavigationItem> get navigationItems => [
    NavigationItem(
      routePath: '/patient/list',
      title: 'Patients',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      screen: const PatientsScreen(),
    ),
  ];

  @override
  Future<void> initialize() async {
    // No initialization needed for Riverpod
  }
}
