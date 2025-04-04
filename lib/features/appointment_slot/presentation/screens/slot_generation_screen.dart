import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/appointment_slot.dart';
import '../providers/slot_generation_notifier.dart';
import '../widgets/slot_generation_form.dart';

class SlotGenerationScreen extends ConsumerStatefulWidget {
  static const routeName = '/slot-generation';

  const SlotGenerationScreen({super.key});

  @override
  ConsumerState<SlotGenerationScreen> createState() => _SlotGenerationScreenState();
}

class _SlotGenerationScreenState extends ConsumerState<SlotGenerationScreen> {
  late final String _doctorId;
  late final AppointmentSlot? _existingSlot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _doctorId = args?['doctorId'] as String? ?? '';
    _existingSlot = args?['slot'] as AppointmentSlot?;
  }

  @override
  Widget build(BuildContext context) {
    final generationState = ref.watch(slotGenerationNotifierProvider);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SlotGenerationForm(
              doctorId: _doctorId,
              existingSlot: _existingSlot,
              onGenerationComplete: _handleGenerationComplete,
            ),
          ),
          if (generationState.isLoading)
            Center(child: const Text('Generating slots...')),
        ],
      ),
    );
  }

  void _handleGenerationComplete(Result<List<AppointmentSlot>> result) {
    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully generated ${result.data.length} new slots'),
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}