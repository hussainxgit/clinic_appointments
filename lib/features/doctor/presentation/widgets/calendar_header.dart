import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/ui/theme/app_colors.dart';
import '../../../../core/ui/theme/app_theme.dart';

class CalendarHeader extends StatelessWidget {
  final String doctorId;
  final CalendarFormat calendarFormat;
  final Function(String) onAddSlot;
  final Function(CalendarFormat) onFormatChanged;

  const CalendarHeader({
    super.key,
    required this.doctorId,
    required this.calendarFormat,
    required this.onAddSlot,
    required this.onFormatChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Slot'),
                onPressed: () => onAddSlot(doctorId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8.0),
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
    final isSelected = calendarFormat == format;
    return GestureDetector(
      onTap: () => onFormatChanged(format),
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
}
