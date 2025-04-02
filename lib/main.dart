// lib/main.dart
import 'package:clinic_appointments/features/dashboard/dashboard_module.dart';
import 'package:clinic_appointments/features/payment/payment_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/messaging/messaging_module.dart';
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
  // Load environment variables
  await dotenv.load(fileName: ".env");
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
  featureRegistry.registerModule(DashboardModule());
  featureRegistry.registerModule(DoctorModule());
  featureRegistry.registerModule(PatientModule());
  featureRegistry.registerModule(AppointmentSlotModule());
  featureRegistry.registerModule(AppointmentModule());
  featureRegistry.registerModule(PaymentModule());
  featureRegistry.registerModule(MessagingModule());

  await featureRegistry.initializeAllModules();

  runApp(ProviderScope(child: ClinicApp(featureRegistry: featureRegistry)));
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
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final navigationItems = widget.featureRegistry.allNavigationItems;

    if (navigationItems.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          // Collapsible Side Navigation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 200 : 70,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    red: 0,
                    green: 0,
                    blue: 0,
                    alpha: 0.2,
                  ),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(height: 50),
                // Toggle button
                IconButton(
                  icon: Icon(
                    _isExpanded
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                SizedBox(height: 20),
                // Navigation items
                Expanded(
                  child: ListView.builder(
                    itemCount: navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = navigationItems[index];
                      return NavItem(
                        title: item.title,
                        icon:
                            index == _selectedIndex
                                ? item.selectedIcon
                                : item.icon,
                        isSelected: index == _selectedIndex,
                        isExpanded: _isExpanded,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(child: navigationItems[_selectedIndex].screen),
        ],
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  const NavItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).primaryColorLight
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white70),
            if (isExpanded)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
