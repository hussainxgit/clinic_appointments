// lib/core/ui/base_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/core_providers.dart';

abstract class BaseScreen extends ConsumerWidget {
  const BaseScreen({super.key});

  String get screenTitle;
  bool get showBackButton => true;

  Widget buildContent(BuildContext context, WidgetRef ref);
  List<Widget> buildActions(BuildContext context, WidgetRef ref) => [];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        leading:
            showBackButton
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => navigationService.goBack(),
                )
                : null,
        actions: buildActions(context, ref),
      ),
      body: buildContent(context, ref),
    );
  }
}
