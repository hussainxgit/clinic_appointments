import 'package:flutter/material.dart';
import '../../domain/entities/appointment_slot.dart';
import '../widgets/slot_generation_form.dart';

class SlotManagementScreen extends StatefulWidget {
  const SlotManagementScreen({super.key});

  @override
  State<SlotManagementScreen> createState() => _SlotManagementScreenState();
}

class _SlotManagementScreenState extends State<SlotManagementScreen> {
  String? _doctorId;
  AppointmentSlot? _existingSlot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null) {
      if (args is Map<String, dynamic>) {
        // Handle map arguments
        _doctorId = args['doctorId'] as String?;
        _existingSlot = args['slot'] as AppointmentSlot?;
      } else if (args is AppointmentSlot) {
        // Handle direct slot argument
        _existingSlot = args;
        _doctorId = args.doctorId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _existingSlot != null
              ? 'Edit Slot Configuration'
              : 'Generate Appointment Slots',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SlotGenerationForm(
          doctorId: _doctorId ?? '',
          existingSlot: _existingSlot,
          onGenerationComplete: (result) {
            if (result.isSuccess && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Successfully generated ${result.data.length} slots',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${result.error}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
