import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../features/appointment/domain/entities/appointment.dart';
import '../../../../features/appointment/presentation/providers/appointment_notifier.dart';
import '../../../../features/doctor/domain/entities/doctor.dart';

class UpcomingAppointmentsWidget extends ConsumerStatefulWidget {
  const UpcomingAppointmentsWidget({super.key});

  @override
  ConsumerState<UpcomingAppointmentsWidget> createState() =>
      _UpcomingAppointmentsWidgetState();
}

class _UpcomingAppointmentsWidgetState
    extends ConsumerState<UpcomingAppointmentsWidget> {
  int _selectedDayIndex = 3; // Default to Wednesday (index 3)
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    // Make today the first day, then show the rest of the week
    final now = DateTime.now();
    _startDate = now; // Start with today
    _selectedDayIndex = 0; // Select first day (today)
  }

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(appointmentNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming\nAppointment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_outward),
                  onPressed: () {
                    // Navigate to appointments screen
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDaySelector(),
            const SizedBox(height: 16),
            Expanded(
              child:
                  appointmentState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildAppointmentsList(appointmentState.appointments),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    return SizedBox(
      height: 65,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        primary: true,
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = _startDate.add(Duration(days: index)); // days from today
          final isSelected = index == _selectedDayIndex;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
              });
            },
            child: Container(
              width: 45,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? const Color(0xFF0F5A5C).withAlpha((1.0 * 255).toInt())
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _getDayName(day.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> allAppointments) {
    // Get selected date
    final selectedDate = _startDate.add(Duration(days: _selectedDayIndex));

    // Filter appointments for selected date
    final appointments =
        allAppointments.where((item) {
          final appointment = item['appointment'] as Appointment;
          return _isSameDay(appointment.dateTime, selectedDate);
        }).toList();

    if (appointments.isEmpty) {
      return _buildEmptySchedule();
    }

    // Sort by time
    appointments.sort((a, b) {
      final aTime = (a['appointment'] as Appointment).dateTime;
      final bTime = (b['appointment'] as Appointment).dateTime;
      return aTime.compareTo(bTime);
    });

    return ListView.builder(
      shrinkWrap: true,
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final item = appointments[index];
        final appointment = item['appointment'] as Appointment;
        final doctor = item['doctor'] as Doctor?;

        return _buildAppointmentItem(appointment, doctor);
      },
    );
  }

  Widget _buildAppointmentItem(Appointment appointment, Doctor? doctor) {
    final timeFormat = DateFormat('h:mm a');
    final startTime = timeFormat.format(appointment.dateTime);

    // Calculate end time (assumed 45 minutes duration)
    final endTime = timeFormat.format(
      appointment.dateTime.add(const Duration(minutes: 45)),
    );

    // Determine background color based on time
    final hour = appointment.dateTime.hour;
    final Color backgroundColor =
        hour < 10
            ? const Color(0xFFFFD480) // Morning (yellow)
            : const Color(0xFF78D7DB); // Afternoon (teal)

    return InkWell(
      onTap:
          () => ref
              .read(navigationServiceProvider)
              .navigateTo('/appointment-slot/details'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(appointment.dateTime).split(' ')[0],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  timeFormat.format(appointment.dateTime).split(' ')[1],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    if (doctor?.imageUrl != null)
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(doctor!.imageUrl!),
                        onBackgroundImageError:
                            (_, __) => const Icon(Icons.person),
                      )
                    else
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          doctor?.name.isNotEmpty == true
                              ? doctor!.name[0]
                              : 'D',
                          style: TextStyle(
                            color: backgroundColor.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meet with dr.${doctor?.name.split(' ').last ?? 'Unknown'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$startTime - $endTime',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Column(
      children: [
        // Time indicator
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '09:00',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'AM',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Add New Schedule',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7]; // Correctly maps 1-7 to 0-6
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
