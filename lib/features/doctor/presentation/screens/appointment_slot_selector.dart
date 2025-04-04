import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/theme/app_colors.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../features/appointment_slot/domain/entities/appointment_slot.dart';
import '../../../../features/appointment_slot/domain/entities/time_slot.dart';
import '../../../../features/appointment_slot/presentation/providers/appointment_slot_notifier.dart';
import '../widgets/calendar_header.dart';
import '../widgets/slot_details.dart';

class AppointmentSlotSelector extends ConsumerStatefulWidget {
  final String doctorId;
  final Function(AppointmentSlot, TimeSlot) onTimeSlotSelected;
  final Function(DateTime)? onDateSelected;

  const AppointmentSlotSelector({
    super.key,
    required this.doctorId,
    required this.onTimeSlotSelected,
    this.onDateSelected,
  });

  @override
  ConsumerState<AppointmentSlotSelector> createState() =>
      _AppointmentSlotSelectorState();
}

class _AppointmentSlotSelectorState
    extends ConsumerState<AppointmentSlotSelector> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay =
      DateTime.now(); // Initialize directly, remove nullable
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    // Remove redundant assignment since we initialized _selectedDay above
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final slotsState = ref.watch(appointmentSlotNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalendarHeader(
          doctorId: widget.doctorId,
          calendarFormat: _calendarFormat,
          onAddSlot: _addNewSlot,
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
        ),
        _buildCalendarView(slotsState),
        const SizedBox(height: 12),
        SingleChildScrollView(
          
          child: _buildDaySlotSummary(slotsState)),
      ],
    );
  }

  Map<DateTime, SlotSummary> _calculateSlotSummaries(
    AppointmentSlotState slotsState,
  ) {
    return Map.fromEntries(
      slotsState.slots.where((s) => s.doctorId == widget.doctorId).map((slot) {
        final date = DateTime(slot.date.year, slot.date.month, slot.date.day);
        return MapEntry(
          date,
          SlotSummary(
            availableCount: slot.availableSpots,
            bookedCount: slot.totalBookedPatients,
            isFullyBooked: slot.isFullyBooked,
          ),
        );
      }),
    );
  }

  Widget _buildCalendarView(AppointmentSlotState slotsState) {
    final slotSummaries = _calculateSlotSummaries(slotsState);

    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 30)),
      lastDay: DateTime.now().add(const Duration(days: 180)),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primary),
        rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primary),
        titleTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
        weekendStyle: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        if (widget.onDateSelected != null) {
          widget.onDateSelected!(selectedDay);
        }
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
        todayDecoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: const TextStyle(color: Colors.red),
        disabledTextStyle: TextStyle(color: Colors.grey[400]),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final summary =
              slotSummaries[DateTime(date.year, date.month, date.day)];
          return summary != null
              ? Positioned(
                bottom: 1,
                right: 1,
                child: _buildDateMarker(summary),
              )
              : null;
        },
        defaultBuilder: _buildDefaultDayCell,
      ),
    );
  }

  Widget? _buildDefaultDayCell(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
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
  }

  Widget _buildDateMarker(SlotSummary summary) {
    Color color;
    if (summary.isFullyBooked) {
      color = Colors.red;
    } else if (summary.bookedCount > 0) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildDaySlotSummary(AppointmentSlotState slotsState) {
    if (slotsState.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final daySlots = _getFilteredDaySlots(slotsState);

    if (daySlots.isEmpty) {
      return EmptyState(
        message:
            "No appointment slots on ${DateFormat.yMMMMd().format(_selectedDay)}",
        icon: Icons.event_busy,
        onAction: () => _addNewSlot(widget.doctorId),
        actionLabel: "Add Slot",
      );
    }

    return SlotDetails(daySlot: daySlots.first);
  }

  List<AppointmentSlot> _getFilteredDaySlots(AppointmentSlotState slotsState) {
    return slotsState.slots
        .where(
          (slot) =>
              slot.doctorId == widget.doctorId &&
              isSameDay(slot.date, _selectedDay) &&
              slot.isActive,
        )
        .toList();
  }

  void _addNewSlot(String doctorId) {
    final navigationService = ref.read(navigationServiceProvider);
    navigationService.navigateTo(
      '/appointment-slot/add',
      arguments: {'doctorId': doctorId, 'date': _selectedDay},
    );
  }
}

class SlotSummary {
  final int availableCount;
  final int bookedCount;
  final bool isFullyBooked;

  SlotSummary({
    required this.availableCount,
    required this.bookedCount,
    required this.isFullyBooked,
  });
}
