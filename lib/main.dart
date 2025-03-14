// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/di/core_providers.dart';
import 'core/ui/theme/app_theme.dart';

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
  }

  runApp(
    const ProviderScope(
      child: ClinicApp(),
    ),
  );
}

class ClinicApp extends ConsumerWidget {
  const ClinicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.watch(navigationServiceProvider);
    final featureRegistry = ref.watch(featureRegistryProvider);
    final scaffoldKey = ref.watch(scaffoldMessengerKeyProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eye Clinic App',
      theme: AppTheme.lightTheme,
      navigatorKey: navigationService.navigatorKey,
      scaffoldMessengerKey: scaffoldKey,
      routes: featureRegistry.allRoutes,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final featureRegistry = ref.watch(featureRegistryProvider);
    final navigationItems = featureRegistry.allNavigationItems;

    if (navigationItems.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No features registered yet.\nTransitioning to new architecture.',
            textAlign: TextAlign.center,
          ),
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