// lib/features/appointment/presentation/screens/appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../providers/appointment_notifier.dart';
import '../../domain/entities/appointment.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../../doctor/domain/entities/doctor.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;
  final DateFormat _dateFormat = DateFormat('EEE, MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              navigationService.navigateTo('/appointment/create');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by patient or doctor name',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon:
                        _searchQuery.isNotEmpty || _selectedDate != null
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedDate = null;
                                });
                              },
                            )
                            : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                if (_selectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            'Date: ${_dateFormat.format(_selectedDate!)}',
                          ),
                          onDeleted: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Appointment lists in tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentList('scheduled'),
                _buildAppointmentList('completed'),
                _buildAppointmentList('cancelled'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null, // Disables Hero animations
        child: const Icon(Icons.add),
        onPressed: () {
          navigationService.navigateTo('/appointment/create');
        },
      ),
    );
  }

  Widget _buildAppointmentList(String status) {
    final appointmentState = ref.watch(appointmentNotifierProvider);

    if (appointmentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (appointmentState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${appointmentState.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      ref
                          .read(appointmentNotifierProvider.notifier)
                          .refreshAppointments(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Filter appointments by status and search query
    final filteredAppointments =
        appointmentState.appointments.where((item) {
          final appointment = item['appointment'] as Appointment;
          final patient = item['patient'] as Patient?;
          final doctor = item['doctor'] as Doctor?;

          // Filter by status
          final statusMatch = appointment.status == status;

          // Filter by search query
          final searchMatch =
              _searchQuery.isEmpty ||
              (patient?.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false) ||
              (doctor?.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false);

          // Filter by date
          final dateMatch =
              _selectedDate == null || appointment.isSameDay(_selectedDate!);

          return statusMatch && searchMatch && dateMatch;
        }).toList();

    if (filteredAppointments.isEmpty) {
      return EmptyState(
        message: 'No $status appointments found',
        icon: Icons.event_busy,
        actionLabel: status == 'scheduled' ? 'Add Appointment' : null,
        onAction:
            status == 'scheduled'
                ? () {
                  ref
                      .read(navigationServiceProvider)
                      .navigateTo('/appointment/create');
                }
                : null,
      );
    }

    return RefreshIndicator(
      onRefresh:
          () =>
              ref
                  .read(appointmentNotifierProvider.notifier)
                  .refreshAppointments(),
      child: ListView.builder(
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          final item = filteredAppointments[index];
          final appointment = item['appointment'] as Appointment;
          final patient = item['patient'] as Patient?;
          final doctor = item['doctor'] as Doctor?;

          return _buildAppointmentItem(appointment, patient, doctor);
        },
      ),
    );
  }

  Widget _buildAppointmentItem(
    Appointment appointment,
    Patient? patient,
    Doctor? doctor,
  ) {
    final statusColor =
        appointment.status == 'scheduled'
            ? Colors.blue
            : appointment.status == 'completed'
            ? Colors.green
            : Colors.red;

    final dateTime = DateFormat(
      'E, MMM d, yyyy • h:mm a',
    ).format(appointment.dateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(
            appointment.status == 'scheduled'
                ? Icons.schedule
                : appointment.status == 'completed'
                ? Icons.check
                : Icons.cancel,
            color: Colors.white,
          ),
        ),
        title: Text(patient?.name ?? 'Unknown Patient'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor?.name ?? 'Unknown Doctor'),
            Text(dateTime),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.status.capitalize(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        appointment.paymentStatus == 'paid'
                            ? Colors.green.withOpacity(0.2)
                            : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.paymentStatus.capitalize(),
                    style: TextStyle(
                      color:
                          appointment.paymentStatus == 'paid'
                              ? Colors.green
                              : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildActionButtons(appointment),
        onTap: () {
          ref
              .read(navigationServiceProvider)
              .navigateTo(
                '/appointment/details',
                arguments: {
                  'appointment': appointment,
                  'patient': patient,
                  'doctor': doctor,
                },
              );
        },
      ),
    );
  }

  Widget _buildActionButtons(Appointment appointment) {
    if (appointment.status == 'scheduled') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => _completeAppointment(appointment),
            tooltip: 'Complete',
            color: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () => _cancelAppointment(appointment),
            tooltip: 'Cancel',
            color: Colors.red,
          ),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () {
          ref
              .read(navigationServiceProvider)
              .navigateTo(
                '/appointment/details',
                arguments: {'appointment': appointment},
              );
        },
        tooltip: 'Details',
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _completeAppointment(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Complete Appointment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mark this appointment as completed?'),
                const SizedBox(height: 16),
                const Text('Payment Status:'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: appointment.paymentStatus,
                  items: const [
                    DropdownMenuItem(value: 'paid', child: Text('Paid')),
                    DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
                  ],
                  onChanged: (value) {
                    // This would be handled in the dialog result
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Complete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final notifier = ref.read(appointmentNotifierProvider.notifier);
      final result = await notifier.completeAppointment(
        appointment.id,
        paymentStatus:
            'paid', // You would get this from the dialog in a real app
      );

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
            content: Text('Appointment completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
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
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final notifier = ref.read(appointmentNotifierProvider.notifier);
      final result = await notifier.cancelAppointment(appointment.id);

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
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
