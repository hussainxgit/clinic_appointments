// lib/core/di/service_locator.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../navigation/navigation_service.dart';
import '../events/event_bus.dart';
import '../module/feature_registry.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Register core services
  sl.registerSingleton<NavigationService>(NavigationServiceImpl());
  sl.registerSingleton<EventBus>(EventBus());
  sl.registerSingleton<FeatureRegistry>(FeatureRegistry());
  
  // Register global messenger key
  sl.registerSingleton<GlobalKey<ScaffoldMessengerState>>(
    GlobalKey<ScaffoldMessengerState>()
  );
}

class ServiceLocator {
  static T get<T extends Object>() => sl<T>();
  
  static void registerSingleton<T extends Object>(T instance) {
    if (!sl.isRegistered<T>()) {
      sl.registerSingleton<T>(instance);
    }
  }
  
  static void registerLazySingleton<T extends Object>(T Function() factory) {
    if (!sl.isRegistered<T>()) {
      sl.registerLazySingleton<T>(factory);
    }
  }
}