// lib/core/ui/base_screen.dart
import 'package:flutter/material.dart';
import '../di/service_locator.dart';
import '../navigation/navigation_service.dart';

abstract class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key});

  String get screenTitle;
  bool get showBackButton => true;
  
  Widget buildContent(BuildContext context);
  List<Widget> buildActions(BuildContext context) => [];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ServiceLocator.get<NavigationService>().goBack(),
              )
            : null,
        actions: buildActions(context),
      ),
      body: buildContent(context),
    );
  }
}