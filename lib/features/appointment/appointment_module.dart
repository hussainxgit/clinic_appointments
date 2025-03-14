// lib/features/appointment/appointment_module.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/single_child_widget.dart';

import '../../core/module/feature_module.dart';
import '../../core/di/service_locator.dart';
import '../../core/events/event_bus.dart';
import 'data/appointment_repository.dart';
import 'presentation/providers/appointment_provider.dart';
import '../patient/data/patient_repository.dart';
import '../doctor/data/doctor_repository.dart';
import '../appointment_slot/data/appointment_slot_repository.dart';
import 'presentation/screens/appointment_screens.dart';
import 'services/appointment_service.dart';

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
  List<SingleChildWidget> get providers => [
    Provider<AppointmentService>(
      create: (context) => AppointmentService(
        appointmentRepository: ServiceLocator.get<AppointmentRepository>(),
        patientRepository: ServiceLocator.get<PatientRepository>(),
        doctorRepository: ServiceLocator.get<DoctorRepository>(),
        slotRepository: ServiceLocator.get<AppointmentSlotRepository>(),
        eventBus: ServiceLocator.get<EventBus>(),
      ),
    ),
    ChangeNotifierProvider<AppointmentProvider>(
      create: (context) => AppointmentProvider(
        appointmentService: context.read<AppointmentService>(),
      ),
    ),
  ];

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
    // Register repository
    ServiceLocator.registerLazySingleton<AppointmentRepository>(
      () => AppointmentRepositoryImpl(
        firestore: FirebaseFirestore.instance,
      ),
    );
  }
}