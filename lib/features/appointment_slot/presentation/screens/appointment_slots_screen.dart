// lib/features/appointment_slot/presentation/screens/appointment_slots_screen.dart
import 'package:clinic_appointments/features/doctor/domain/entities/doctor.dart';
import 'package:clinic_appointments/features/doctor/presentation/provider/doctor_notifier.dart';
import 'package:clinic_appointments/features/patient/presentation/providers/patient_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../patient/domain/entities/patient.dart';
import '../providers/appointment_slot_notifier.dart';
import '../../domain/entities/appointment_slot.dart';

class AppointmentSlotsScreen extends ConsumerStatefulWidget {
  const AppointmentSlotsScreen({super.key});

  @override
  ConsumerState<AppointmentSlotsScreen> createState() =>
      _AppointmentSlotsScreenState();
}

class _AppointmentSlotsScreenState
    extends ConsumerState<AppointmentSlotsScreen> {
  String? _selectedDoctorId;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed:
                () => ref
                    .read(navigationServiceProvider)
                    .navigateTo('/appointment-slot/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(
              context,
            ).primaryColor.withAlpha((0.1 * 255).toInt()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${_selectedDate != null ? DateFormat('EEE, MMM d').format(_selectedDate!) : 'Select Date'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDoctorDropdown(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.filter_alt),
                      label: const Text('Apply Filters'),
                      onPressed: () {
                        setState(() {}); // Refresh with filters
                      },
                    ),
                    TextButton(
                      child: const Text('Clear Filters'),
                      onPressed: () {
                        setState(() {
                          _selectedDoctorId = null;
                          _selectedDate = DateTime.now();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Slot list
          Expanded(child: _buildSlotsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // Disables Hero animations
        child: const Icon(Icons.add),
        onPressed: () {
          // navigationService.navigateTo('/appointment-slot/add');
        },
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    final doctorState = ref.watch(doctorNotifierProvider);

    if (doctorState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final doctors = doctorState.doctors;
    if (doctors.isEmpty) {
      return const Text('No doctors available');
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Doctor',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      value: _selectedDoctorId,
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('All Doctors')),
        ...doctors.map(
          (doctor) => DropdownMenuItem<String>(
            value: doctor.id,
            child: Text(doctor.name),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedDoctorId = value;
        });
      },
    );
  }

  Widget _buildSlotsList() {
    final slotState = ref.watch(appointmentSlotNotifierProvider);

    if (slotState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (slotState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${slotState.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      ref
                          .read(appointmentSlotNotifierProvider.notifier)
                          .refreshSlots(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Apply filters
    final slots = ref
        .read(appointmentSlotNotifierProvider.notifier)
        .getSlots(doctorId: _selectedDoctorId, date: _selectedDate);

    if (slots.isEmpty) {
      return EmptyState(
        message: 'No appointment slots found for the selected filters',
        icon: Icons.event_busy,
        actionLabel: 'Add Slot',
        onAction: () {
          ref
              .read(navigationServiceProvider)
              .navigateTo('/appointment-slot/add');
        },
      );
    }

    final doctorState = ref.watch(doctorNotifierProvider);

    return RefreshIndicator(
      onRefresh:
          () =>
              ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots(),
      child: ListView.builder(
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          final doctor = doctorState.doctors.firstWhere(
            (d) => d.id == slot.doctorId,
            orElse:
                () => Doctor(
                  id: slot.doctorId,
                  name: 'Unknown Doctor',
                  specialty: '',
                  phoneNumber: '',
                ),
          );
          return _buildSlotItem(slot, doctor.name);
        },
      ),
    );
  }

  Widget _buildSlotItem(AppointmentSlot slot, String doctorName) {
    final navigationService = ref.read(navigationServiceProvider);
    final doctorState = ref.watch(doctorNotifierProvider);
    final patientState = ref.watch(patientNotifierProvider);

    final availabilityColor = slot.isFullyBooked ? Colors.red : Colors.green;
    final timeString = DateFormat('h:mm a').format(slot.date);
    final dateString = DateFormat('EEE, MMM d').format(slot.date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(doctorName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateString at $timeString'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  slot.isFullyBooked ? Icons.event_busy : Icons.event_available,
                  color: availabilityColor.withAlpha((1.0 * 255).toInt()),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${slot.timeSlots.length} booked',
                  style: TextStyle(
                    color: availabilityColor.withAlpha((1.0 * 255).toInt()),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                navigationService.navigateTo(
                  '/appointment-slot/edit',
                  arguments: slot,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed:
                  slot.hasBookedPatients ? null : () => _confirmDelete(slot),
              color: slot.hasBookedPatients ? Colors.grey : Colors.red,
            ),
          ],
        ),
        onTap: () {
          // View slot details or edit
          navigationService.navigateTo(
            '/appointment-slot/details',
            arguments: {
              'slot': slot,
              'doctor': doctorState.doctors.firstWhere(
                (d) => d.id == slot.doctorId,
                orElse:
                    () => Doctor(
                      id: slot.doctorId,
                      name: 'Unknown Doctor',
                      specialty: '',
                      phoneNumber: '',
                    ),
              ),
              'patient': patientState.patients.firstWhere(
                (d) => d.id == slot.doctorId,
                orElse:
                    () => Patient(
                      id: slot.doctorId,
                      name: 'Unknown Patient',
                      phone: '',
                      registeredAt: DateTime.now(),
                    ),
              ),
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(AppointmentSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text(
              'Are you sure you want to delete this appointment slot?\n\n'
              'Doctor: ${slot.doctorId}\n'
              'Date: ${DateFormat('EEE, MMM d, yyyy').format(slot.date)}\n'
              'Time: ${DateFormat('h:mm a').format(slot.date)}',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final result = await ref
          .read(appointmentSlotNotifierProvider.notifier)
          .removeSlot(slot.id);

      if (result.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment slot deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
