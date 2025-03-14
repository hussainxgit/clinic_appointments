// lib/features/doctor/doctor_module_riverpod.dart
import 'package:clinic_appointments/features/doctor/data/doctor_provider.dart';
import 'package:clinic_appointments/features/doctor/presentation/provider/doctor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/module/feature_module.dart';
import 'presentation/screens/doctors_screen.dart';
import 'presentation/screens/doctor_form_screen.dart';

class DoctorModule implements FeatureModule {
  @override
  String get moduleId => 'doctor';

  @override
  String get moduleName => 'Doctor Management';

  @override
  String? get moduleDescription =>
      'Manage clinic doctors and their availability';

  @override
  List<String> get dependsOn => [];

  @override
  List<ProviderBase> get providers => [
    doctorNotifierProvider,
    doctorRepositoryProvider,
  ];

  @override
  Map<String, WidgetBuilder> get routes => {
        '/doctor/list': (_) => const DoctorsScreen(),
        '/doctor/add': (_) => const DoctorFormScreen(isEditing: false),
        '/doctor/edit': (_) => const DoctorFormScreen(isEditing: true),
      };

  @override
  List<NavigationItem> get navigationItems => [
        NavigationItem(
          routePath: '/doctor/list',
          title: 'Doctors',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          screen: const DoctorsScreen(),
        ),
      ];

  @override
  Future<void> initialize() async {
    // No need to register repositories with GetIt
  }
}