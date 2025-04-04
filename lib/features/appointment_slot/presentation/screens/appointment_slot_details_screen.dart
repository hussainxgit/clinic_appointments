import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../../appointment/domain/entities/appointment.dart';
import '../../../appointment/presentation/providers/appointment_notifier.dart';
import '../../../doctor/domain/entities/doctor.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../domain/entities/appointment_slot.dart';
import '../../presentation/providers/appointment_slot_notifier.dart';

class AppointmentSlotDetailsScreen extends ConsumerStatefulWidget {
  const AppointmentSlotDetailsScreen({super.key});

  @override
  AppointmentSlotDetailsState createState() => AppointmentSlotDetailsState();
}

class AppointmentSlotDetailsState
    extends ConsumerState<AppointmentSlotDetailsScreen> {
  String? slotId;
  int _selectedPatientIndex = 0;
  String? _searchQuery;
  bool _dataInitialized = false;

  @override
  void initState() {
    super.initState();

    // Defer getting arguments until after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _initializeData() {
    if (!mounted) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    setState(() {
      slotId = args?['slotId'] as String?;
    });

    // Load data only once
    if (slotId != null && !_dataInitialized) {
      // Check if the data is already loaded
      final slotState = ref.read(appointmentSlotNotifierProvider);
      final appointmentState = ref.read(appointmentNotifierProvider);

      // Only load data if it's not already being loaded or if we need fresh data
      if (!slotState.isLoading && !appointmentState.isLoading) {
        // Use a single refresh if possible
        ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots();
        ref.read(appointmentNotifierProvider.notifier).refreshAppointments();
        _dataInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get only what we need from providers
    final slotState = ref.watch(appointmentSlotNotifierProvider);
    final appointmentState = ref.watch(appointmentNotifierProvider);

    final isLoading = slotState.isLoading || appointmentState.isLoading;

    // Find the slot
    final slot =
        slotId != null
            ? slotState.slots.firstWhere(
              (s) => s.id == slotId,
              orElse:
                  () => AppointmentSlot(
                    id: '',
                    doctorId: '',
                    date: DateTime.now(),
                    timeSlots: [],
                  ),
            )
            : null;

    // Get appointments for this slot - only when needed
    final slotAppointments =
        slotId != null
            ? appointmentState.appointments.where((item) {
              final appointment = item['appointment'] as Appointment;
              return appointment.appointmentSlotId == slotId;
            }).toList()
            : [];

    // Apply search filter if needed
    final filteredAppointments =
        _searchQuery != null && _searchQuery!.isNotEmpty
            ? slotAppointments.where((item) {
              final patient = item['patient'] as Patient?;
              if (patient == null) return false;

              final query = _searchQuery!.toLowerCase();
              return patient.name.toLowerCase().contains(query) ||
                  patient.phone.toLowerCase().contains(query) ||
                  (patient.email?.toLowerCase().contains(query) ?? false);
            }).toList()
            : slotAppointments;

    // Loading state
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Slot not found
    if (slot == null || slot.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Slot Details')),
        body: const EmptyState(
          message: 'Appointment slot not found',
          icon: Icons.calendar_today_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Slot Patients - ${_formatDate(slot.date)}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () => _configureSlot(slot),
              tooltip: 'Configure slot',
              icon: const Icon(Icons.settings),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LoadingButton(
              text: 'Add patient',
              onPressed: _addPatientToSlot,
              icon: Icons.add,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchAndFilterBar(),
            const SizedBox(height: 16),

            Expanded(
              child:
                  filteredAppointments.isEmpty
                      ? const EmptyState(
                        message: 'No patients assigned to this slot',
                        icon: Icons.people_outline,
                        actionLabel: 'Add Patient',
                      )
                      : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildPatientsList(
                              filteredAppointments.cast<Map<String, dynamic>>(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: _buildPatientDetails(
                              filteredAppointments.cast<Map<String, dynamic>>(),
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            // Filter functionality would go here
          },
          icon: const Icon(Icons.filter_list),
          label: const Text('Filter'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            // Sort functionality would go here
          },
          icon: const Icon(Icons.sort),
          label: const Text('Sort'),
        ),
      ],
    );
  }

  Widget _buildPatientsList(List<Map<String, dynamic>> appointments) {
    return AppCard(
      child: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final patient = appointments[index]['patient'] as Patient?;
          final appointment = appointments[index]['appointment'] as Appointment;

          if (patient == null) {
            return const ListTile(title: Text('Patient not found'));
          }

          return InkWell(
            onTap: () {
              setState(() {
                _selectedPatientIndex = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                selected: _selectedPatientIndex == index,
                selectedTileColor:
                    Theme.of(context).colorScheme.primaryContainer,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(patient.name[0].toUpperCase()),
                ),
                title: Text(patient.name),
                subtitle: Text(_getAppointmentStatusText(appointment)),
                trailing: IconButton(
                  onPressed: () => _editAppointment(appointment),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit appointment',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientDetails(List<Map<String, dynamic>> appointments) {
    if (appointments.isEmpty) {
      return const EmptyState(
        message: 'Select a patient to view details',
        icon: Icons.person_outline,
      );
    }

    // Ensure the selected index is valid
    final validIndex =
        _selectedPatientIndex < appointments.length ? _selectedPatientIndex : 0;

    final patient = appointments[validIndex]['patient'] as Patient?;
    final appointment = appointments[validIndex]['appointment'] as Appointment;
    final doctor = appointments[validIndex]['doctor'] as Doctor?;

    if (patient == null) {
      return const EmptyState(
        message: 'Patient information not available',
        icon: Icons.error_outline,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 350,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPatientProfileCard(patient)),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAppointmentDetailsCard(appointment, doctor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildPatientNotesSection(appointment, patient),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildPatientStatusCard(patient)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientProfileCard(Patient patient) {
    return AppCard(
      elevation: 3,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildPatientImage(patient.avatarUrl),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPatientInfoOverlay(patient),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientImage(String? avatarUrl) {
    // Use placeholder image if no avatar is available
    final imageUrl =
        avatarUrl?.isNotEmpty == true
            ? avatarUrl
            : 'https://www.nvisioncenters.com/wp-content/uploads/types-of-eye-care-professionals.jpg';

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
          ),
        );
      },
      errorBuilder:
          (context, error, stackTrace) => Center(
            child: Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
    );
  }

  Widget _buildPatientInfoOverlay(Patient patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withAlpha((0.7 * 255).toInt()),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  patient.dateOfBirth != null
                      ? '${_calculateAge(patient.dateOfBirth!)} years old, ${_formatDate(patient.dateOfBirth!)}'
                      : 'No birth date available',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                if (patient.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    patient.email!,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _contactPatient(patient, 'sms'),
                icon: const Icon(Icons.chat_rounded, color: Colors.white),
                tooltip: 'Message patient',
              ),
              IconButton(
                onPressed: () => _contactPatient(patient, 'call'),
                icon: const Icon(Icons.call_rounded, color: Colors.white),
                tooltip: 'Call patient',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDetailsCard(Appointment appointment, Doctor? doctor) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appointment Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () => _editAppointment(appointment),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit appointment',
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      'Status',
                      _getAppointmentStatusText(appointment),
                    ),
                    _buildDetailItem('Date', _formatDate(appointment.dateTime)),
                    _buildDetailItem('Time', _formatTime(appointment.dateTime)),
                    _buildDetailItem('Doctor', doctor?.name ?? 'Not assigned'),
                    _buildDetailItem(
                      'Payment',
                      appointment.paymentStatus.toString().split('.').last,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      appointment.status != AppointmentStatus.cancelled
                          ? () => _cancelAppointment(appointment)
                          : null,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed:
                      appointment.status != AppointmentStatus.completed
                          ? () => _completeAppointment(appointment)
                          : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientNotesSection(Appointment appointment, Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Appointment Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editAppointmentNotes(appointment),
                      tooltip: 'Edit notes',
                    ),
                  ],
                ),
                Expanded(
                  child: Text(
                    appointment.notes ??
                        'No notes available for this appointment.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Container(
            height: 120,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Patient Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editPatient(patient),
                      tooltip: 'Edit notes',
                    ),
                  ],
                ),
                Expanded(
                  child: Text(
                    patient.notes ?? 'No notes available for this patient.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientStatusCard(Patient patient) {
    return AppCard(
      child: Container(
        height: 256,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              'Status',
              patient.status.toString().split('.').last,
              patient.status == PatientStatus.active
                  ? Colors.green
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            _buildStatusItem(
              'Appointments',
              '${patient.appointmentIds.length}',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildStatusItem(
              'Registered',
              _formatDate(patient.registeredAt),
              Colors.purple,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _viewPatientDetails(patient),
                icon: const Icon(Icons.person),
                label: const Text('View Full Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  // Action methods
  void _addPatientToSlot() {
    if (slotId == null) return;

    Navigator.of(
      context,
    ).pushNamed('/appointment/create', arguments: {'slotId': slotId}).then((_) {
      // Only refresh appointment data after returning
      ref.read(appointmentNotifierProvider.notifier).refreshAppointments();
    });
  }

  void _configureSlot(AppointmentSlot slot) {
    Navigator.of(
      context,
    ).pushNamed('/appointment-slot/edit', arguments: {'slot': slot}).then((_) {
      // Only refresh slot data after returning
      ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots();
    });
  }

  void _editAppointment(Appointment appointment) {
    Navigator.of(context)
        .pushNamed(
          '/appointment/edit',
          arguments: {'appointmentId': appointment.id},
        )
        .then((_) {
          // Only refresh appointment data after returning
          ref.read(appointmentNotifierProvider.notifier).refreshAppointments();
        });
  }

  void _cancelAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: const Text(
              'Are you sure you want to cancel this appointment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Use try-catch to avoid unnecessary state updates on error
        final result = await ref
            .read(appointmentNotifierProvider.notifier)
            .cancelAppointment(appointment.id);

        if (result.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment cancelled successfully')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: ${result.error}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _completeAppointment(Appointment appointment) async {
    try {
      final result = await ref
          .read(appointmentNotifierProvider.notifier)
          .completeAppointment(appointment.id);

      if (result.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment marked as completed')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete: ${result.error}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _editAppointmentNotes(Appointment appointment) async {
    final updatedNotes = await showDialog<String>(
      context: context,
      builder:
          (context) => _NotesDialog(
            title: 'Edit Appointment Notes',
            initialNotes: appointment.notes,
          ),
    );

    if (updatedNotes != null) {
      try {
        final updatedAppointment = appointment.copyWith(notes: updatedNotes);
        final result = await ref
            .read(appointmentNotifierProvider.notifier)
            .updateAppointment(updatedAppointment);

        if (result.isSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notes updated successfully')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update notes: ${result.error}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  void _editPatient(Patient patient) {
    Navigator.of(
      context,
    ).pushNamed('/patient/edit', arguments: {'patient': patient}).then((_) {
      // Force a specific refresh only when returning
      ref.read(appointmentNotifierProvider.notifier).refreshAppointments();
    });
  }

  void _contactPatient(Patient patient, String method) {
    if (method == 'call') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling ${patient.name} at ${patient.phone}')),
      );
    } else {
      Navigator.of(context).pushNamed(
        '/messaging',
        arguments: {'recipient': patient.phone, 'name': patient.name},
      );
    }
  }

  void _viewPatientDetails(Patient patient) {
    Navigator.of(
      context,
    ).pushNamed('/patient/details', arguments: {'patientId': patient.id});
  }

  // Utility methods
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _getAppointmentStatusText(Appointment appointment) {
    switch (appointment.status) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Helper dialog for editing notes
class _NotesDialog extends StatefulWidget {
  final String title;
  final String? initialNotes;

  const _NotesDialog({required this.title, this.initialNotes});

  @override
  _NotesDialogState createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter notes here...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
