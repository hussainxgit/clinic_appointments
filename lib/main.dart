import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import 'shared/services/service_factory.dart';
import 'shared/ui/navigation_scaffold.dart';
import 'shared/utilities/globals.dart' as globals;
import 'shared/utilities/my_theme.dart';

void main() {

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentSlotProvider()),
        ProxyProvider4<AppointmentProvider, PatientProvider, DoctorProvider,
            AppointmentSlotProvider, ClinicService>(
          update: (_, ap, pp, dp, asp, __) =>
              ServiceFactory.createClinicService(
            globals.scaffoldMessengerKey,
            ap,
            pp,
            dp,
            asp,
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
    ),
  );
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
      screen: Center(child: Text('Settings')),
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
