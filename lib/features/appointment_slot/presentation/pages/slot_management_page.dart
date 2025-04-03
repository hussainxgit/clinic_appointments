import 'package:flutter/material.dart';
import '../../domain/entities/appointment_slot.dart';
import '../widgets/slot_generation_form.dart';

class SlotManagementPage extends StatefulWidget {
  const SlotManagementPage({super.key});

  @override
  State<SlotManagementPage> createState() => _SlotManagementPageState();
}

class _SlotManagementPageState extends State<SlotManagementPage> {
  String? _doctorId;
  DateTime? _initialDate;
  AppointmentSlot? _existingSlot;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null) {
      if (args is Map<String, dynamic>) {
        // Handle map arguments
        _doctorId = args['doctorId'] as String?;
        _initialDate = args['date'] as DateTime?;
        _existingSlot = args['slot'] as AppointmentSlot?;
      } else if (args is AppointmentSlot) {
        // Handle direct slot argument
        _existingSlot = args;
        _doctorId = args.doctorId;
        _initialDate = args.date;
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
          initialDate: _initialDate,
          existingSlot: _existingSlot,
        ),
      ),
    );
  }
}
