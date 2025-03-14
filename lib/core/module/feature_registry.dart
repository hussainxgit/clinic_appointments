import 'package:clinic_appointments/core/module/feature_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureRegistry {
  final Map<String, FeatureModule> _modules = {};
  
  void registerModule(FeatureModule module) {
    if (_modules.containsKey(module.moduleId)) return;
    _modules[module.moduleId] = module;
  }
  
  List<FeatureModule> get modules => _modules.values.toList();
  
  List<ProviderBase> get allProviders => 
    modules.expand((module) => module.providers).toList();
    
  Map<String, WidgetBuilder> get allRoutes {
    final routes = <String, WidgetBuilder>{};
    for (final module in modules) {
      routes.addAll(module.routes);
    }
    return routes;
  }
  
  List<NavigationItem> get allNavigationItems =>
    modules.expand((module) => module.navigationItems).toList();
    
  Future<void> initializeAllModules() async {
    for (final module in modules) {
      await module.initialize();
    }
  }
}