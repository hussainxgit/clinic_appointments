import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/core_providers.dart';
import '../../../appointment/domain/entities/appointment.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';
import '../../../appointment/presentation/providers/appointment_notifier.dart';
import '../../domain/entities/doctor.dart';
import '../provider/doctor_notifier.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final doctor = ModalRoute.of(context)!.settings.arguments as Doctor;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(doctor, theme),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(doctor, theme),
                      const SizedBox(height: 24),
                      _buildQuickActions(doctor),
                      const SizedBox(height: 24),
                      _buildInfoTabs(doctor, theme),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomAction(doctor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Doctor doctor, ThemeData theme) {
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(doctor.name, style: theme.textTheme.titleLarge),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareDoctor(doctor),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  () => ref
                      .read(navigationServiceProvider)
                      .navigateTo('/doctor/edit', arguments: doctor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Doctor doctor, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  doctor.imageUrl != null
                      ? NetworkImage(doctor.imageUrl!)
                      : null,
              backgroundColor: theme.colorScheme.primaryContainer,
              child:
                  doctor.imageUrl == null
                      ? Text(
                        doctor.name[0].toUpperCase(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name, style: theme.textTheme.headlineSmall),
                  Text(
                    doctor.specialty,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text('4.8 (124 reviews)'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      doctor.isAvailable ? 'Available' : 'Unavailable',
                      style: TextStyle(
                        color:
                            doctor.isAvailable
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    backgroundColor:
                        doctor.isAvailable
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.errorContainer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(Doctor doctor) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(
          icon: Icons.phone,
          label: 'Call',
          onPressed: () => _callDoctor(doctor),
        ),
        _buildActionButton(
          icon: Icons.message,
          label: 'Message',
          onPressed: () => _messageDoctor(doctor),
        ),
        _buildActionButton(
          icon: Icons.videocam,
          label: 'Video',
          onPressed: () => _videoCallDoctor(doctor),
        ),
        _buildActionButton(
          icon: Icons.email,
          label: 'Email',
          onPressed: () => _emailDoctor(doctor),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 100,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon), const SizedBox(height: 4), Text(label)],
        ),
      ),
    );
  }

  Widget _buildInfoTabs(Doctor doctor, ThemeData theme) {
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'About'),
              Tab(text: 'Schedule'),
              Tab(text: 'Patients'),
              Tab(text: 'Reviews'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildAboutTab(doctor),
                _buildScheduleTab(doctor),
                _buildPatientsTab(doctor),
                _buildReviewsTab(doctor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(Doctor doctor) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (doctor.bio != null && doctor.bio!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(doctor.bio!, style: theme.textTheme.bodyLarge),
          ),
        ListTile(
          leading: const Icon(Icons.medical_services),
          title: const Text('Specializations'),
          subtitle: const Text(
            'Ophthalmology, Retina Surgery, Cataract Surgery',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Phone'),
          subtitle: Text(doctor.phoneNumber),
        ),
        if (doctor.email != null)
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(doctor.email!),
          ),
        ListTile(
          leading: const Icon(Icons.school),
          title: const Text('Education'),
          subtitle: const Text('University Medical School'),
        ),
        if (doctor.socialMedia != null && doctor.socialMedia!.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Social Media'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  doctor.socialMedia!.entries
                      .map((e) => Text('${e.key}: ${e.value}'))
                      .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildScheduleTab(Doctor doctor) {
    final slotState = ref.watch(appointmentSlotNotifierProvider);
    final theme = Theme.of(context);

    if (slotState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final slots = ref
        .read(appointmentSlotNotifierProvider.notifier)
        .getSlots(doctorId: doctor.id, date: _selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed:
                    () => setState(
                      () =>
                          _selectedDate = _selectedDate.subtract(
                            const Duration(days: 1),
                          ),
                    ),
              ),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed:
                    () => setState(
                      () =>
                          _selectedDate = _selectedDate.add(
                            const Duration(days: 1),
                          ),
                    ),
              ),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: () => _addNewSlot(doctor),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text('Add New Slot'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child:
              slots.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No slots for ${DateFormat('MMM d').format(_selectedDate)}',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _addNewSlot(doctor),
                          child: const Text('Add a slot'),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: slots.length,
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final isAvailable = !slot.isFullyBooked;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  isAvailable
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(
                            DateFormat('h:mm a').format(slot.date),
                            style: theme.textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            isAvailable
                                ? '${slot.bookedPatients}/${slot.maxPatients} booked'
                                : 'Fully booked',
                            style: TextStyle(
                              color:
                                  isAvailable
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.error,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editSlot(slot),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color:
                                    slot.bookedPatients > 0
                                        ? theme.colorScheme.onSurfaceVariant
                                        : theme.colorScheme.error,
                                onPressed:
                                    slot.bookedPatients > 0
                                        ? null
                                        : () => _deleteSlot(slot),
                              ),
                            ],
                          ),
                          onTap: () => _editSlot(slot),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildPatientsTab(Doctor doctor) {
    final appointmentState = ref.watch(appointmentNotifierProvider);
    final theme = Theme.of(context);

    if (appointmentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final appointments =
        appointmentState.appointments
            .where(
              (item) =>
                  item['appointment'].doctorId == doctor.id &&
                  item['appointment'].status == AppointmentStatus.scheduled,
            )
            .toList();

    return appointments.isEmpty
        ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No scheduled appointments',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        )
        : ListView.builder(
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index]['appointment'];
            final patient = appointments[index]['patient'];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    patient?.name[0].toUpperCase() ?? '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  patient?.name ?? 'Unknown Patient',
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  DateFormat('MMM d, h:mm a').format(appointment.dateTime),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _viewPatientDetails(patient),
              ),
            );
          },
        );
  }

  Widget _buildReviewsTab(Doctor doctor) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Text('4.8', style: theme.textTheme.headlineLarge),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < 4 ? Icons.star : Icons.star_half,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text('124 reviews'),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children:
                      [5, 4, 3, 2, 1]
                          .map(
                            (rating) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text('$rating'),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: rating / 5 * 0.9,
                                      backgroundColor:
                                          theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(Doctor doctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: () => _showBookingDialog(context, doctor),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Book Appointment'),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showBookingDialog(BuildContext context, Doctor doctor) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Book Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a date to see ${doctor.name}'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(DateFormat('MMMM d, yyyy').format(_selectedDate)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  DefaultTabController.of(
                    context,
                  ).animateTo(1); // Switch to Schedule tab
                },
                child: const Text('See Available Times'),
              ),
            ],
          ),
    );
  }

  void _callDoctor(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${doctor.name} at ${doctor.phoneNumber}...'),
      ),
    );
  }

  void _messageDoctor(Doctor doctor) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Messaging ${doctor.name}...')));
  }

  void _videoCallDoctor(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting video call with ${doctor.name}...')),
    );
  }

  void _emailDoctor(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Emailing ${doctor.email ?? 'No email'}...')),
    );
  }

  void _shareDoctor(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${doctor.name}\'s profile...')),
    );
  }

  void _addNewSlot(Doctor doctor) {
    ref
        .read(navigationServiceProvider)
        .navigateTo(
          '/appointment-slot/add',
          arguments: {'doctorId': doctor.id, 'date': _selectedDate},
        );
  }

  void _editSlot(dynamic slot) {
    ref
        .read(navigationServiceProvider)
        .navigateTo('/appointment-slot/edit', arguments: slot);
  }

  Future<void> _deleteSlot(dynamic slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Slot'),
            content: Text(
              'Delete slot on ${DateFormat('MMM d, h:mm a').format(slot.date)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final slotNotifier = ref.read(appointmentSlotNotifierProvider.notifier);
      final result = await slotNotifier.removeSlot(slot.id);
      setState(() => _isLoading = false);

      if (result.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Slot deleted')));
      }
    }
  }

  void _viewPatientDetails(dynamic patient) {
    if (patient != null) {
      ref
          .read(navigationServiceProvider)
          .navigateTo('/patient/details', arguments: patient);
    }
  }
}
