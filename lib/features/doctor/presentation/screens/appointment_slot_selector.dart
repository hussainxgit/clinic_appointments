import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../features/appointment_slot/domain/entities/appointment_slot.dart';
import '../../../../features/appointment_slot/domain/entities/time_slot.dart';
import '../../../../features/appointment_slot/presentation/providers/appointment_slot_notifier.dart';

class AppointmentSlotSelector extends ConsumerStatefulWidget {
  final String doctorId;
  final Function(AppointmentSlot, TimeSlot) onTimeSlotSelected;

  const AppointmentSlotSelector({
    super.key,
    required this.doctorId,
    required this.onTimeSlotSelected,
  });

  @override
  ConsumerState<AppointmentSlotSelector> createState() =>
      _AppointmentSlotSelectorState();
}

class _AppointmentSlotSelectorState
    extends ConsumerState<AppointmentSlotSelector> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  TimeSlot? _selectedTimeSlot;
  AppointmentSlot? _selectedAppointmentSlot;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Load slots when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final slotsState = ref.watch(appointmentSlotNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCalendar(slotsState),
        const SizedBox(height: 16),
        _buildDaySlotsSection(slotsState),
      ],
    );
  }

  Widget _buildCalendar(AppointmentSlotState slotsState) {
    // Calculate days with available slots
    final availableDates =
        slotsState.slots
            .where(
              (slot) =>
                  slot.doctorId == widget.doctorId &&
                  !slot.isFullyBooked &&
                  slot.isActive,
            )
            .map(
              (slot) =>
                  DateTime(slot.date.year, slot.date.month, slot.date.day),
            )
            .toSet();

    return AppCard(
      elevation: 2,
      padding: const EdgeInsets.all(8),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
          CalendarFormat.twoWeeks: '2 Weeks',
          CalendarFormat.week: 'Week',
        },
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _selectedTimeSlot = null;
            _selectedAppointmentSlot = null;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          markersMaxCount: 3,
          todayDecoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (availableDates.contains(
              DateTime(date.year, date.month, date.day),
            )) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
              );
            }
            return null;
          },
          defaultBuilder: (context, day, focusedDay) {
            // Disable past dates
            if (day.isBefore(
              DateTime.now().subtract(const Duration(days: 1)),
            )) {
              return Container(
                margin: const EdgeInsets.all(4),
                alignment: Alignment.center,
                child: Text(
                  day.day.toString(),
                  style: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildDaySlotsSection(AppointmentSlotState slotsState) {
    if (slotsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedDay == null) {
      return const EmptyState(
        message: "Please select a date to view available slots",
        icon: Icons.calendar_today,
      );
    }

    // Filter slots for the selected day and doctor
    final daySlots =
        slotsState.slots
            .where(
              (slot) =>
                  slot.doctorId == widget.doctorId &&
                  isSameDay(slot.date, _selectedDay!) &&
                  slot.isActive,
            )
            .toList();

    if (daySlots.isEmpty) {
      return EmptyState(
        message:
            "No appointment slots available for ${DateFormat.yMMMMd().format(_selectedDay!)}",
        icon: Icons.event_busy,
        actionLabel: "Check Another Day",
        onAction:
            () => setState(() {
              _selectedDay = _focusedDay.add(const Duration(days: 1));
              _focusedDay = _selectedDay!;
            }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            "Available Times - ${DateFormat.yMMMMd().format(_selectedDay!)}",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _buildTimeSlotChips(daySlots),
        ),
      ],
    );
  }

  List<Widget> _buildTimeSlotChips(List<AppointmentSlot> daySlots) {
    final List<Widget> timeSlotChips = [];

    for (final slot in daySlots) {
      for (final timeSlot in slot.timeSlots) {
        if (timeSlot.isAvailable) {
          final startTimeStr = _formatTimeOfDay(timeSlot.startTime);
          final endTimeStr = _formatTimeOfDay(timeSlot.endTime);

          final isSelected =
              _selectedTimeSlot?.id == timeSlot.id &&
              _selectedAppointmentSlot?.id == slot.id;

          timeSlotChips.add(
            ChoiceChip(
              label: Text('$startTimeStr - $endTimeStr'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTimeSlot = timeSlot;
                    _selectedAppointmentSlot = slot;
                    widget.onTimeSlotSelected(slot, timeSlot);
                  } else {
                    _selectedTimeSlot = null;
                    _selectedAppointmentSlot = null;
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }
      }
    }

    return timeSlotChips;
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
