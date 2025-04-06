import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../domain/entities/doctor.dart';
import '../provider/doctor_notifier.dart';
import 'appointment_slot_display.dart';
import 'calendar_slot_selector.dart';
import 'doctor_profile_section.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  const DoctorDetailScreen({super.key});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final doctor = ModalRoute.of(context)!.settings.arguments as Doctor;
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => navigationService.navigateTo(
                  '/doctor/edit',
                  arguments: doctor,
                ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side - Doctor Profile
                  Expanded(
                    flex: 1,
                    child: DoctorProfileSection(
                      doctor: doctor,
                      onViewAppointments: () => _viewAppointments(doctor),
                      onCall: () => _callDoctor(doctor),
                      onMessage: () => _messageDoctor(doctor),
                      onToggleAvailability:
                          (value) => _toggleAvailability(doctor, value),
                    ),
                  ),
                  // Right side - Calendar and Slots
                  Expanded(
                    flex: 2,
                    child: AppCard(
                      margin: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Calendar selector
                            CalendarSlotSelector(
                              doctorId: doctor.id,
                              initialDate: _selectedDate,
                              onDateSelected:
                                  (date) =>
                                      setState(() => _selectedDate = date),
                              onAddSlot: (doctorId) => _addSlot(doctorId),
                            ),
                            const SizedBox(height: 8),
                            Divider(thickness: 0.5),
                            const SizedBox(height: 8),
                            // Appointment slots display
                            AppointmentSlotDisplay(
                              doctorId: doctor.id,
                              selectedDate: _selectedDate,
                              onAddSlot: () => _addSlot(doctor.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  void _viewAppointments(Doctor doctor) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/appointment/list',
      arguments: {'doctorId': doctor.id},
    );
  }

  void _callDoctor(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${doctor.name} at ${doctor.phoneNumber}'),
      ),
    );
  }

  void _messageDoctor(Doctor doctor) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/messaging',
      arguments: {'recipient': doctor.phoneNumber},
    );
  }

  void _addSlot(String doctorId) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/appointment-slot/add',
      arguments: {'doctorId': doctorId, 'date': _selectedDate},
    );
  }

  Future<void> _toggleAvailability(Doctor doctor, bool isAvailable) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doctorNotifier = ref.read(doctorNotifierProvider.notifier);
      final updatedDoctor = doctor.copyWith(isAvailable: isAvailable);
      final result = await doctorNotifier.updateDoctor(updatedDoctor);

      if (mounted) {
        if (result.isFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${result.error}')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAvailable
                    ? 'Doctor is now available for appointments'
                    : 'Doctor is now unavailable for appointments',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
