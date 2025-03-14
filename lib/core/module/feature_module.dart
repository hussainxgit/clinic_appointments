// lib/core/module/feature_module.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class FeatureModule {
  String get moduleId;
  String get moduleName;
  String? get moduleDescription => null;
  List<String> get dependsOn => [];
  
  List<ProviderBase> get providers => [];
  Map<String, WidgetBuilder> get routes;
  List<NavigationItem> get navigationItems => [];
  
  Future<void> initialize() async {}
}

class NavigationItem {
  final String routePath;
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
  
  NavigationItem({
    required this.routePath,
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}