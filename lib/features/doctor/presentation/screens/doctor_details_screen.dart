import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/theme/app_theme.dart';
import '../../../appointment/presentation/providers/appointment_notifier.dart';
import '../../../appointment_slot/domain/entities/appointment_slot.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../domain/entities/doctor.dart';
import '../provider/doctor_notifier.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  const DoctorDetailScreen({super.key});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Preload doctor's slots
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctorSlots();
    });
  }

  Future<void> _loadDoctorSlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading slots: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Doctor Profile
          Expanded(
            flex: 1,
            child: DoctorProfileSection(
              doctor: doctor,
              onAddSlot: () => _addNewSlot(doctor),
              onViewAppointments: () => _viewAppointments(doctor),
              onCall: () => _callDoctor(doctor),
              onMessage: () => _messageDoctor(doctor),
              onToggleAvailability:
                  (value) => _toggleAvailability(doctor, value),
            ),
          ),

          // Right side - Calendar
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Appointment Schedule',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Slot'),
                            onPressed: () => _addNewSlot(doctor),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCalendar(doctor),
                    const Divider(),
                    Expanded(
                      child:
                          _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : AppointmentSlotsList(
                                doctor: doctor,
                                selectedDay: _selectedDay,
                                onEditSlot: _editSlot,
                                onDeleteSlot: _deleteSlot,
                                onViewDetails:
                                    (slot) =>
                                        _viewAppointmentDetails(slot, ref),
                                onAddSlot:
                                    () =>
                                        _addNewSlot(doctor, date: _selectedDay),
                              ),
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

  Widget _buildCalendar(Doctor doctor) {
    final slots =
        ref
            .watch(appointmentSlotNotifierProvider)
            .slots
            .where((slot) => slot.doctorId == doctor.id)
            .toList();

    // Get dates that have slots
    final eventDates = <DateTime, List<String>>{};
    for (final slot in slots) {
      final date = DateTime(slot.date.year, slot.date.month, slot.date.day);
      // Add to date events map - create list if not exists, otherwise append
      if (!eventDates.containsKey(date)) {
        eventDates[date] = ['hasSlots'];
      }
    }

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        // Convert day to the same format as stored keys
        final date = DateTime(day.year, day.month, day.day);
        return eventDates[date] ?? [];
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      calendarStyle: CalendarStyle(
        markersMaxCount: 1,
        markerDecoration: BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppTheme.accentColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(formatButtonShowsNext: false),
    );
  }

  void _viewAppointmentDetails(AppointmentSlot slot, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/appointment-slot/details',
      arguments: {'slotId': slot.id},
    );
  }

  void _addNewSlot(Doctor doctor, {DateTime? date}) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/appointment-slot/add',
      arguments: {
        'doctorId': doctor.id,
        'date': date ?? _selectedDay ?? DateTime.now(),
      },
    );
  }

  void _editSlot(AppointmentSlot slot) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo('/appointment-slot/edit', arguments: slot);
  }

  Future<void> _deleteSlot(AppointmentSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Slot'),
            content: Text(
              'Are you sure you want to delete this slot on ${DateFormat('MMM d, h:mm a').format(slot.date)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final slotNotifier = ref.read(appointmentSlotNotifierProvider.notifier);
        final result = await slotNotifier.removeSlot(slot.id);

        if (mounted) {
          if (result.isFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: ${result.error}')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Slot deleted successfully')),
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

  void _viewAppointments(Doctor doctor) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/appointment/list',
      arguments: {'doctorId': doctor.id},
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
}

// Doctor Profile Section Widget
class DoctorProfileSection extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onAddSlot;
  final VoidCallback onViewAppointments;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final Function(bool) onToggleAvailability;

  const DoctorProfileSection({
    super.key,
    required this.doctor,
    required this.onAddSlot,
    required this.onViewAppointments,
    required this.onCall,
    required this.onMessage,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      color: Colors.grey[50],
      child: Stack(
        children: [
          // Header with gradient background
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.7),
                  AppTheme.primaryColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content with curved top
          Column(
            children: [
              // Header content
              DoctorProfileHeader(doctor: doctor),

              // Action buttons
              DoctorActionButtons(
                onSchedule: onAddSlot,
                onAppointments: onViewAppointments,
                onCall: onCall,
                onMessage: onMessage,
              ),

              // Content in scrollview
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DoctorAvailabilityCard(
                          doctor: doctor,
                          onToggleAvailability: onToggleAvailability,
                        ),
                        const SizedBox(height: 16),
                        DoctorContactInfoCard(doctor: doctor),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Doctor Profile Header Widget
class DoctorProfileHeader extends StatelessWidget {
  final Doctor doctor;

  const DoctorProfileHeader({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              foregroundImage:
                  doctor.imageUrl != null
                      ? NetworkImage(doctor.imageUrl!)
                      : null,
              child:
                  doctor.imageUrl == null
                      ? Text(
                        doctor.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          color: AppTheme.primaryColor,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Dr. ${doctor.name}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              doctor.specialty,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Doctor Action Buttons Widget
class DoctorActionButtons extends StatelessWidget {
  final VoidCallback onSchedule;
  final VoidCallback onAppointments;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const DoctorActionButtons({
    super.key,
    required this.onSchedule,
    required this.onAppointments,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            context: context,
            icon: Icons.calendar_today,
            label: 'Schedule',
            onPressed: onSchedule,
          ),
          _buildActionButton(
            context: context,
            icon: Icons.assignment,
            label: 'Appointments',
            onPressed: onAppointments,
          ),
          _buildActionButton(
            context: context,
            icon: Icons.phone,
            label: 'Call',
            onPressed: onCall,
          ),
          _buildActionButton(
            context: context,
            icon: Icons.message,
            label: 'Message',
            onPressed: onMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppTheme.primaryColor, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Doctor Availability Card Widget
class DoctorAvailabilityCard extends StatelessWidget {
  final Doctor doctor;
  final Function(bool) onToggleAvailability;

  const DoctorAvailabilityCard({
    super.key,
    required this.doctor,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Availability',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        doctor.isAvailable
                            ? AppTheme.successColor.withValues(alpha: 0.2)
                            : AppTheme.errorColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    doctor.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color:
                          doctor.isAvailable
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doctor.isAvailable
                      ? 'Accepting appointments'
                      : 'Not available for appointments',
                  style: TextStyle(
                    color:
                        doctor.isAvailable
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                  ),
                ),
                Switch(
                  value: doctor.isAvailable,
                  onChanged: onToggleAvailability,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Doctor Contact Info Card Widget
class DoctorContactInfoCard extends StatelessWidget {
  final Doctor doctor;

  const DoctorContactInfoCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade50,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'Contact Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.phone, 'Phone', doctor.phoneNumber),
                if (doctor.email != null)
                  _buildInfoRow(Icons.email, 'Email', doctor.email!),
                if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(doctor.bio!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

// Appointment Slots List Widget
class AppointmentSlotsList extends ConsumerWidget {
  final Doctor doctor;
  final DateTime? selectedDay;
  final Function(AppointmentSlot) onEditSlot;
  final Function(AppointmentSlot) onDeleteSlot;
  final Function(AppointmentSlot) onViewDetails;
  final VoidCallback onAddSlot;

  const AppointmentSlotsList({
    super.key,
    required this.doctor,
    required this.selectedDay,
    required this.onEditSlot,
    required this.onDeleteSlot,
    required this.onViewDetails,
    required this.onAddSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedDay == null) return const SizedBox.shrink();

    // Use watch instead of read to react to state changes
    final slotState = ref.watch(appointmentSlotNotifierProvider);

    if (slotState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final slots =
        slotState.slots.where((slot) {
          return slot.doctorId == doctor.id &&
              _isSameDate(slot.date, selectedDay!);
        }).toList();

    if (slots.isEmpty) {
      return EmptySlotList(selectedDay: selectedDay!, onAddSlot: onAddSlot);
    }

    // Sort slots by time
    slots.sort((a, b) => a.date.compareTo(b.date));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final slot = slots[index];
        return AppointmentSlotItem(
          slot: slot,
          onEdit: () => onEditSlot(slot),
          onDelete: () => onDeleteSlot(slot),
          onViewDetails: () => onViewDetails(slot),
        );
      },
    );
  }

  // Helper function to check if two dates are the same day
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

// Empty Slot List Widget
class EmptySlotList extends StatelessWidget {
  final DateTime selectedDay;
  final VoidCallback onAddSlot;

  const EmptySlotList({
    super.key,
    required this.selectedDay,
    required this.onAddSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No slots for ${DateFormat('MMMM d, yyyy').format(selectedDay)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Slot'),
            onPressed: onAddSlot,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Appointment Slot Item Widget
class AppointmentSlotItem extends ConsumerWidget {
  final AppointmentSlot slot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const AppointmentSlotItem({
    super.key,
    required this.slot,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time = DateFormat('h:mm a').format(slot.date);
    final isAvailable = !slot.isFullyBooked;

    // Determine status info
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isAvailable) {
      statusText = 'Available';
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'Fully Booked';
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.event_busy;
    }

    return Card(
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              isAvailable
                  ? AppTheme.successColor.withValues(alpha: 0.08)
                  : AppTheme.warningColor.withValues(alpha: 0.08),
              Colors.white,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onViewDetails,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with time and actions
                Row(
                  children: [
                    // Time section with border
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.access_time, color: AppTheme.primaryColor),
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Slot details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status indicator
                            Row(
                              children: [
                                Icon(statusIcon, size: 16, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Capacity progress indicator
                          ],
                        ),
                      ),
                    ),

                    // Actions column
                    Column(
                      children: [
                        Material(
                          color: AppTheme.infoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onEdit,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit,
                                size: 20,
                                color: AppTheme.infoColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color:
                              slot.timeSlots.isNotEmpty
                                  ? Colors.grey.shade200
                                  : AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: slot.timeSlots.isNotEmpty ? null : onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.delete,
                                size: 20,
                                color:
                                    slot.timeSlots.isNotEmpty
                                        ? Colors.grey.shade400
                                        : AppTheme.errorColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Patient avatars section - only if there are booked patients
                if (slot.timeSlots.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  PatientAvatarSection(slot: slot),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Patient Avatar Section Widget
class PatientAvatarSection extends ConsumerWidget {
  final AppointmentSlot slot;

  const PatientAvatarSection({super.key, required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get appointment data for this slot
    final appointmentState = ref.watch(appointmentNotifierProvider);
    final appointments =
        appointmentState.appointments
            .where(
              (item) => slot.timeSlots.contains(item['appointment'].id),
            )
            .toList();

    // No appointments found
    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Maximum number of avatars to show
    const int maxVisibleAvatars = 5;
    final int totalPatients = appointments.length;
    final bool hasMorePatients = totalPatients > maxVisibleAvatars;
    final int visibleCount =
        hasMorePatients ? maxVisibleAvatars - 1 : totalPatients;
    final int remainingCount = totalPatients - visibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 16, color: AppTheme.infoColor),
            const SizedBox(width: 8),
            Text(
              'Booked Patients',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.infoColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: Row(
            children: [
              // Visible patient avatars
              for (int i = 0; i < visibleCount && i < appointments.length; i++)
                PatientAvatar(appointmentData: appointments[i]),

              // "More" indicator if needed
              if (hasMorePatients)
                MorePatientsIndicator(remainingCount: remainingCount),

              const Spacer(),

              // Button to view all patients
              OutlinedButton.icon(
                onPressed:
                    () {}, // This will be handled by parent onViewDetails
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View All'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 32),
                  side: BorderSide(
                    color: AppTheme.infoColor.withValues(alpha: 0.5),
                  ),
                  foregroundColor: AppTheme.infoColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Patient Avatar Widget
class PatientAvatar extends StatelessWidget {
  final Map<String, dynamic> appointmentData;

  const PatientAvatar({super.key, required this.appointmentData});

  @override
  Widget build(BuildContext context) {
    final patient = appointmentData['patient'] as Patient?;

    if (patient == null) {
      return _buildDefaultAvatar();
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CircleAvatar(
        radius: 20,
        child: Tooltip(
          message: patient.name,
          child: ClipOval(
            child: Image.network(
              patient.avatarUrl ?? '',
              fit: BoxFit.cover,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Center(
          child: Text(
            '?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// More Patients Indicator Widget
class MorePatientsIndicator extends StatelessWidget {
  final int remainingCount;

  const MorePatientsIndicator({super.key, required this.remainingCount});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$remainingCount more patient${remainingCount > 1 ? 's' : ''}',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            '+$remainingCount',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
