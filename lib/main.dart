import 'package:clinic_appointments/features/doctor/controller/doctor_provider.dart';
import 'package:clinic_appointments/features/doctor/view/doctor_profile.dart';

import 'features/appointment/controller/appointment_provider.dart';
import 'features/doctor_availability/controller/doctor_availability_provdier.dart';
import 'features/patient/controller/patient_provider.dart';
import 'features/patient/view/patients_screen.dart';
import 'shared/utilities/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/appointment/view/add_appointment_dialog.dart';
import 'features/appointment/view/appointments_screen.dart';
import 'features/dashboard/view/dashboard_screen.dart';
import 'shared/provider/clinic_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize providers
  final appointmentProvider = AppointmentProvider();
  final patientProvider = PatientProvider();
  final doctorProvider = DoctorProvider();
  final doctorAvailabilityProvider = DoctorAvailabilityProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => appointmentProvider),
        ChangeNotifierProvider(create: (_) => patientProvider),
        ChangeNotifierProvider(create: (_) => doctorProvider),
        ChangeNotifierProvider(create: (_) => doctorAvailabilityProvider),
        // Using ProxyProvider to pass updated providers to ClinicService
        ProxyProvider4<AppointmentProvider, PatientProvider, DoctorProvider,
            DoctorAvailabilityProvider, ClinicService>(
          update: (_, appointmentProvider, patientProvider, doctorProvider,
                  doctorAvailabilityProvider, __) =>
              ClinicService(
            appointmentProvider: appointmentProvider,
            patientProvider: patientProvider,
            doctorProvider: doctorProvider,
            doctorAvailabilityProvider: doctorAvailabilityProvider,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clinic Appointments Ophth',
        theme: MyTheme.lightTheme,
        home: const MainNavigation(),
      ),
    ),
  );
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Define your tabs here
  final List<TabItem> _tabs = [
    TabItem(
      screen: DashboardScreen(
        totalPatients: 50,
        totalAppointments: 50,
        activeAppointmentsToday: 25,
        completedAppointments: 25,
        cancelledAppointments: 0,
        appointments: [],
      ),
      title: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
    ),
    TabItem(
      screen: const AppointmentsScreen(),
      title: 'Appointments',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
    TabItem(
      screen: const PatientsScreen(),
      title: 'Patients',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    TabItem(
      screen: const Center(child: Text('Settings')),
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  // Generate Navigator keys for each tab
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [];

  @override
  void initState() {
    super.initState();
    // Initialize navigator keys for each tab
    _navigatorKeys.addAll(
        List.generate(_tabs.length, (index) => GlobalKey<NavigatorState>()));
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWide) _buildNavigationRail(context),
          if (isWide) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(context, _tabs[_selectedIndex].title),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _tabs.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Navigator(
                          key: _navigatorKeys[entry.key],
                          onGenerateRoute: (settings) => MaterialPageRoute(
                            builder: (context) => entry.value.screen,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _tabs.map((tab) {
                return NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.title,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      extended: true,
      minExtendedWidth: 180,
      leading: const AppTitle(),
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      labelType: NavigationRailLabelType.none,
      destinations: _tabs.map((tab) {
        return NavigationRailDestination(
          icon: Icon(tab.icon),
          selectedIcon: Icon(tab.selectedIcon),
          label: Text(tab.title),
        );
      }).toList(),
    );
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex != index) {
      // Pop to the first route when changing tabs
      _navigatorKeys[_selectedIndex]
          .currentState
          ?.popUntil((route) => route.isFirst);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  // AppBar with Account Avatar
  PreferredSizeWidget _buildAppBar(BuildContext context, [String? title]) {
    return AppBar(
      title: Text(title ?? ""),
      elevation: 0.3,
      actions: [
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AddAppointmentDialog(),
            );
          },
          child: const Text('Add appointment, patient'),
        ),
        IconButton(
          icon: const CircleAvatar(
            radius: 16,
            child: Icon(Icons.person),
          ),
          onPressed: () {
            showMenu(
              context: context,
              position: const RelativeRect.fromLTRB(55, 55, 0, 0),
              items: [
                PopupMenuItem(
                  value: 'account_settings',
                  child: Text('Account Settings'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => DoctorProfile()));
                  },
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ).then((value) {
              if (value == 'account_settings') {
                // Navigate to Account Settings
                print('Account Settings clicked');
              } else if (value == 'logout') {
                // Handle Logout
                print('Logout clicked');
              }
            });
          },
        ),
      ],
    );
  }
}

// Reusable App Title Widget
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Clinic',
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

// TabItem Model
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
