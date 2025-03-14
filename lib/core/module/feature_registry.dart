// lib/core/module/feature_registry.dart
import 'package:flutter/material.dart';
import 'package:provider/single_child_widget.dart';
import 'feature_module.dart';
import '../utils/logger.dart';

class FeatureRegistry {
  final Map<String, FeatureModule> _modules = {};
  final _logger = AppLogger(tag: 'FeatureRegistry');
  
  void registerModule(FeatureModule module) {
    if (_modules.containsKey(module.moduleId)) {
      _logger.warning('Module ${module.moduleId} already registered');
      return;
    }
    
    // Validate dependencies
    for (final dependency in module.dependsOn) {
      if (!_modules.containsKey(dependency)) {
        throw Exception(
          'Module ${module.moduleId} depends on $dependency, but it is not registered'
        );
      }
    }
    
    _modules[module.moduleId] = module;
    _logger.info('Registered module: ${module.moduleName} (${module.moduleId})');
  }
  
  List<FeatureModule> get modules => List.unmodifiable(_modules.values);
  FeatureModule? getModule(String moduleId) => _modules[moduleId];
  
  List<SingleChildWidget> get allProviders => 
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
      _logger.info('Initializing module: ${module.moduleName}');
      await module.initialize();
    }
  }
}