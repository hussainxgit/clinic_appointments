// lib/features/patient/patient_module.dart
import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';
import '../../core/module/feature_module.dart';
import 'presentation/screens/patient_screen.dart';

class PatientModule implements FeatureModule {
  @override
  String get moduleId => 'patient';

  @override
  String get moduleName => 'Patient Management';
  
  @override
  String? get moduleDescription => 'Manage clinic patients and their information';

  @override
  List<String> get dependsOn => [];

  @override
  List<SingleChildWidget> get providers => []; // No longer needed with Riverpod

  @override
  Map<String, WidgetBuilder> get routes => {
    '/patient/list': (_) => const PatientsScreen(),
    // '/patient/details': (_) => const PatientDetailsScreen(),
    // '/patient/add': (_) => const PatientFormScreen(isEditing: false),
    // '/patient/edit': (_) => const PatientFormScreen(isEditing: true),
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