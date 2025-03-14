// lib/core/di/core_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../navigation/navigation_service.dart';
import '../events/event_bus.dart';
import '../module/feature_registry.dart';

// This line tells the generator to create the file core_providers.g.dart
part 'core_providers.g.dart';

// Navigation Service Provider
@riverpod
NavigationService navigationService(Ref ref) {
  return NavigationServiceImpl();
}

// Event Bus Provider
@riverpod
EventBus eventBus(Ref ref) {
  return EventBus();
}
// Feature Registry Provider
@riverpod
FeatureRegistry featureRegistry(Ref ref) {
  return FeatureRegistry();
}

// Global Scaffold Messenger Key Provider
@riverpod
GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey(Ref ref) {
  return GlobalKey<ScaffoldMessengerState>();
}