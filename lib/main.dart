// lib/main.dart
import 'package:clinic_appointments/features/payment/payment_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/di/core_providers.dart';
import 'core/ui/theme/app_theme.dart';
import 'core/module/feature_registry.dart';
import 'features/doctor/doctor_module.dart';
import 'features/patient/patient_module.dart';
import 'features/appointment/appointment_module.dart';
import 'features/appointment_slot/appointment_slot_module.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  // Prepare feature registry
  final featureRegistry = FeatureRegistry();
  
  // Register modules in correct order
  featureRegistry.registerModule(DoctorModule());
  featureRegistry.registerModule(PatientModule());
  featureRegistry.registerModule(AppointmentSlotModule());
  featureRegistry.registerModule(AppointmentModule());
  featureRegistry.registerModule(PaymentModule());

  
  await featureRegistry.initializeAllModules();

  runApp(
    ProviderScope(
      child: ClinicApp(featureRegistry: featureRegistry),
    ),
  );
}

class ClinicApp extends ConsumerWidget {
  final FeatureRegistry featureRegistry;

  const ClinicApp({super.key, required this.featureRegistry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.watch(navigationServiceProvider);
    final scaffoldKey = ref.watch(scaffoldMessengerKeyProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eye Clinic App',
      theme: AppTheme.lightTheme,
      navigatorKey: navigationService.navigatorKey,
      scaffoldMessengerKey: scaffoldKey,
      routes: featureRegistry.allRoutes,
      home: MainNavigationScreen(featureRegistry: featureRegistry),
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  final FeatureRegistry featureRegistry;

  const MainNavigationScreen({super.key, required this.featureRegistry});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final navigationItems = widget.featureRegistry.allNavigationItems;

    if (navigationItems.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: navigationItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: navigationItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.selectedIcon),
            label: item.title,
          );
        }).toList(),
      ),
    );
  }
}