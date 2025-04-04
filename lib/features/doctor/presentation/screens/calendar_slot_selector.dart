import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/ui/theme/app_colors.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';

class CalendarSlotSelector extends ConsumerStatefulWidget {
  final String doctorId;
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final Function(String)? onAddSlot;

  const CalendarSlotSelector({
    super.key,
    required this.doctorId,
    this.initialDate,
    required this.onDateSelected,
    this.onAddSlot,
  });

  @override
  ConsumerState<CalendarSlotSelector> createState() =>
      _CalendarSlotSelectorState();
}

class _CalendarSlotSelectorState extends ConsumerState<CalendarSlotSelector> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDate ?? DateTime.now();
    _focusedDay = _selectedDay;

    // Initialize slots
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final slotsState = ref.watch(appointmentSlotNotifierProvider);
    final slotSummaries = _calculateSlotSummaries(slotsState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildHeader(context), _buildCalendar(slotSummaries)],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Calendar Schedule",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              if (widget.onAddSlot != null) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Slot'),
                  onPressed: () => widget.onAddSlot!(widget.doctorId),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _buildFormatSelector(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _formatButton("Month", CalendarFormat.month),
          _formatButton("Week", CalendarFormat.week),
        ],
      ),
    );
  }

  Widget _formatButton(String text, CalendarFormat format) {
    final isSelected = _calendarFormat == format;
    return GestureDetector(
      onTap: () => setState(() => _calendarFormat = format),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar(Map<DateTime, _SlotSummary> slotSummaries) {
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
        widget.onDateSelected(selectedDay);
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

  Widget _buildDateMarker(_SlotSummary summary) {
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

  Map<DateTime, _SlotSummary> _calculateSlotSummaries(
    AppointmentSlotState slotsState,
  ) {
    return Map.fromEntries(
      slotsState.slots.where((s) => s.doctorId == widget.doctorId).map((slot) {
        final date = DateTime(slot.date.year, slot.date.month, slot.date.day);
        return MapEntry(
          date,
          _SlotSummary(
            availableCount: slot.availableSpots,
            bookedCount: slot.totalBookedPatients,
            isFullyBooked: slot.isFullyBooked,
          ),
        );
      }),
    );
  }
}

class _SlotSummary {
  final int availableCount;
  final int bookedCount;
  final bool isFullyBooked;

  _SlotSummary({
    required this.availableCount,
    required this.bookedCount,
    required this.isFullyBooked,
  });
}
