// lib/core/navigation/navigation_service.dart
import 'package:flutter/material.dart';

abstract class NavigationService {
  GlobalKey<NavigatorState> get navigatorKey;
  Future<T?> navigateTo<T>(String routeName, {Object? arguments});
  Future<T?> replaceTo<T>(String routeName, {Object? arguments});
  void goBack<T>([T? result]);
  void popUntil(String routeName);
}

class NavigationServiceImpl implements NavigationService {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  
  @override
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
  
  @override
  Future<T?> navigateTo<T>(String routeName, {Object? arguments}) {
    return _navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }
  
  @override
  Future<T?> replaceTo<T>(String routeName, {Object? arguments}) {
    return _navigatorKey.currentState!.pushReplacementNamed<T, dynamic>(
      routeName,
      arguments: arguments,
    );
  }
  
  @override
  void goBack<T>([T? result]) {
    _navigatorKey.currentState!.pop<T>(result);
  }
  
  @override
  void popUntil(String routeName) {
    _navigatorKey.currentState!.popUntil(ModalRoute.withName(routeName));
  }
}