import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
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
        title: Text('Doctor Details'),
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
            child: Container(
              height: double.infinity,
              color: Colors.teal.shade50,
              child: Stack(
                children: [
                  // Header with gradient background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade300, Colors.teal.shade700],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Content with curved top
                  Column(
                    children: [
                      // Header content
                      SizedBox(
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
                                            color: Colors.teal.shade700,
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Action buttons
                      Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              context: context,
                              icon: Icons.calendar_today,
                              label: 'Schedule',
                              onPressed: () => _addNewSlot(doctor),
                            ),
                            _buildActionButton(
                              context: context,
                              icon: Icons.assignment,
                              label: 'Appointments',
                              onPressed: () => _viewAppointments(doctor),
                            ),
                            _buildActionButton(
                              context: context,
                              icon: Icons.phone,
                              label: 'Call',
                              onPressed: () => _callDoctor(doctor),
                            ),
                            _buildActionButton(
                              context: context,
                              icon: Icons.message,
                              label: 'Message',
                              onPressed: () => _messageDoctor(doctor),
                            ),
                          ],
                        ),
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
                                _buildAvailabilityWidget(context, doctor),
                                const SizedBox(height: 16),
                                _buildDoctorDetails(context, doctor),
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
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCalendar(doctor),
                    const Divider(),
                    Expanded(child: _buildDaySchedule(doctor)),
                  ],
                ),
              ),
            ),
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
              child: Icon(icon, color: Colors.teal, size: 16),
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

  Widget _buildDoctorDetails(BuildContext context, Doctor doctor) {
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
          ).textTheme.titleMedium?.copyWith(color: Colors.teal.shade800),
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
                      color: Colors.teal.shade800,
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
          Icon(icon, size: 18, color: Colors.teal),
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

  Widget _buildAvailabilityWidget(BuildContext context, Doctor doctor) {
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
                    color: Colors.teal.shade800,
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
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    doctor.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color:
                          doctor.isAvailable
                              ? Colors.green.shade900
                              : Colors.red.shade900,
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
                    color: doctor.isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                Switch(
                  value: doctor.isAvailable,
                  onChanged: (value) => _toggleAvailability(doctor, value),
                  activeColor: Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(Doctor doctor) {
    final slots = ref
        .read(appointmentSlotNotifierProvider.notifier)
        .getSlots(doctorId: doctor.id);

    // Get dates that have slots
    final eventDates = <DateTime>{};
    for (final slot in slots) {
      final date = DateTime(slot.date.year, slot.date.month, slot.date.day);
      eventDates.add(date);
    }

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        final date = DateTime(day.year, day.month, day.day);
        return eventDates.contains(date) ? ['hasSlots'] : [];
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
        markerDecoration: BoxDecoration(
          color: Colors.teal.shade500,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.teal.shade700,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.teal.shade200,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(formatButtonShowsNext: false),
    );
  }

  Widget _buildDaySchedule(Doctor doctor) {
    if (_selectedDay == null) return const SizedBox.shrink();

    final slots = ref
        .read(appointmentSlotNotifierProvider.notifier)
        .getSlots(doctorId: doctor.id, date: _selectedDay);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No slots for ${DateFormat('MMMM d, yyyy').format(_selectedDay!)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Slot'),
              onPressed: () => _addNewSlot(doctor, date: _selectedDay),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Sort slots by time
    slots.sort((a, b) => a.date.compareTo(b.date));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: slots.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final slot = slots[index];
        return _buildSlotItem(slot);
      },
    );
  }

  Widget _buildSlotItem(AppointmentSlot slot) {
    final time = DateFormat('h:mm a').format(slot.date);
    final isAvailable = !slot.isFullyBooked;

    // Calculate availability percentage
    final availabilityPercentage =
        slot.maxPatients > 0
            ? (1 - (slot.bookedPatients / slot.maxPatients)) * 100
            : 0.0;

    // Determine status info
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isAvailable) {
      statusText = 'Available';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'Fully Booked';
      statusColor = Colors.orange;
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
                  ? Colors.green.withOpacity(0.08)
                  : Colors.orange.withOpacity(0.08),
              Colors.white,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {}, // Add any onTap action if needed
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
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.access_time, color: Colors.teal.shade700),
                          const SizedBox(height: 4),
                          Text(
                            time,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal.shade700,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Capacity: ${slot.bookedPatients}/${slot.maxPatients}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${availabilityPercentage.toInt()}% available',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: slot.bookedPatients / slot.maxPatients,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      slot.bookedPatients / slot.maxPatients < 0.8
                                          ? Colors.green
                                          : slot.bookedPatients ==
                                              slot.maxPatients
                                          ? Colors.red
                                          : Colors.orange,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Actions column
                    Column(
                      children: [
                        Material(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _editSlot(slot),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Material(
                          color:
                              slot.bookedPatients > 0
                                  ? Colors.grey.shade200
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap:
                                slot.bookedPatients > 0
                                    ? null
                                    : () => _deleteSlot(slot),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.delete,
                                size: 20,
                                color:
                                    slot.bookedPatients > 0
                                        ? Colors.grey.shade400
                                        : Colors.red.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Patient avatars section - only if there are booked patients
                if (slot.bookedPatients > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildPatientSection(slot, ref),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSection(AppointmentSlot slot, WidgetRef ref) {
    // Get appointment data for this slot
    final appointmentState = ref.watch(appointmentNotifierProvider);
    final appointments =
        appointmentState.appointments
            .where(
              (item) => slot.appointmentIds.contains(item['appointment'].id),
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
            Icon(Icons.people, size: 16, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Text(
              'Booked Patients',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade700,
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
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPatientAvatar(appointments[i]),
                ),

              // "More" indicator if needed
              if (hasMorePatients)
                Tooltip(
                  message:
                      '$remainingCount more patient${remainingCount > 1 ? 's' : ''}',
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
                ),

              const Spacer(),

              // Button to view all patients
              OutlinedButton.icon(
                onPressed: () => _viewAppointmentDetails(slot, ref),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View All'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: const Size(0, 32),
                  side: BorderSide(color: Colors.blue.shade300),
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientAvatar(Map<String, dynamic> appointmentData) {
    final patient = appointmentData['patient'] as Patient?;

    if (patient == null) {
      return _buildDefaultAvatar();
    }

    return CircleAvatar(
      radius: 20,
      child: Tooltip(
        message: patient.name,
        child: ClipOval(
          // Added to ensure circular cropping of the image
          child: Image.network(
            patient.avatarUrl ?? '',
            fit:
                BoxFit
                    .cover, // Changed to cover for better circular image fitting
            width: 40, // 2x radius to fill the CircleAvatar
            height: 40, // 2x radius to fill the CircleAvatar
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
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
    );
  }

  void _viewAppointmentDetails(AppointmentSlot slot, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/appointment-slot/details',
      arguments: {'slot': slot},
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
