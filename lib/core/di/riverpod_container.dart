// lib/core/di/riverpod_container.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final providerContainer = ProviderContainer();

// Helper extension to access providers inside non-widget code
extension ProviderContainerExtension on ProviderContainer {
  T read<T>(ProviderListenable<T> provider) => this.read(provider);
}