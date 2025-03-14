// lib/main.dart
import 'package:clinic_appointments/features/settings/view/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'features/appointment/controller/appointment_provider.dart';
import 'features/appointment/view/appointments_screen.dart';
import 'features/appointment_slot/controller/appointment_slot_provdier.dart';
import 'features/appointment_slot/view/appointment_slot_screen.dart';
import 'features/dashboard/view/dashboard_screen.dart';
import 'features/doctor/view/doctors_screen.dart';
import 'features/patient/controller/patient_provider.dart';
import 'features/doctor/controller/doctor_provider.dart';
import 'features/patient/view/patients_screen.dart';
import 'shared/services/clinic_service.dart';
import 'shared/services/notification_service.dart';
import 'shared/ui/navigation_scaffold.dart';
import 'shared/utilities/globals.dart' as globals;
import 'shared/utilities/my_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue with app initialization even if Firebase fails
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Create domain providers first
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentSlotProvider()),

        // Notification service
        Provider(
          create: (_) =>
              SnackBarNotificationService(globals.scaffoldMessengerKey),
        ),

        // Direct Firestore instance
        Provider(create: (_) => FirebaseFirestore.instance),

        // ClinicService - depends on model providers and notification
        Provider<ClinicService>(
          create: (context) => ClinicService(
            appointmentProvider: context.read<AppointmentProvider>(),
            patientProvider: context.read<PatientProvider>(),
            doctorProvider: context.read<DoctorProvider>(),
            appointmentSlotProvider: context.read<AppointmentSlotProvider>(),
            notificationService: context.read<SnackBarNotificationService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clinic Appointments Ophth',
        theme: MyTheme.lightTheme,
        home: MainNavigation(),
        scaffoldMessengerKey: globals.scaffoldMessengerKey,
      ),
    );
  }
}

class MainNavigation extends StatelessWidget {
  final List<TabItem> tabs = const [
    TabItem(
      screen: DashboardScreen(),
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    TabItem(
      screen: AppointmentSlotScreen(),
      title: 'Appoint. Slots',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
    TabItem(
      screen: AppointmentsScreen(),
      title: 'Appointments',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
    TabItem(
      screen: PatientsScreen(),
      title: 'Patients',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    TabItem(
      screen: DoctorsScreen(),
      title: 'Doctors',
      icon: Icons.emoji_people_outlined,
      selectedIcon: Icons.emoji_people,
    ),
    TabItem(
      screen: SettingsScreen(),
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationScaffold(tabs: tabs);
  }
}

class TabItem {
  final Widget screen;
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  const TabItem({
    required this.screen,
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
}
