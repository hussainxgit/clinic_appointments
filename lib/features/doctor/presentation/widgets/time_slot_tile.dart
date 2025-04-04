import 'package:flutter/material.dart';
import '../../../../core/ui/theme/app_colors.dart';
import '../../../../features/appointment_slot/domain/entities/appointment_slot.dart';
import '../../../../features/appointment_slot/domain/entities/time_slot.dart';

class TimeSlotTile extends StatelessWidget {
  final AppointmentSlot slot;
  final TimeSlot timeSlot;

  const TimeSlotTile({super.key, required this.slot, required this.timeSlot});

  @override
  Widget build(BuildContext context) {
    final startTimeStr = _formatTimeOfDay(timeSlot.startTime);
    final endTimeStr = _formatTimeOfDay(timeSlot.endTime);
    final isAvailable = timeSlot.isAvailable;
    final patientCount = "${timeSlot.bookedPatients}/${timeSlot.maxPatients}";

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: _buildTileContent(
          context,
          startTimeStr,
          endTimeStr,
          isAvailable,
          patientCount,
        ),
      ),
    );
  }

  Widget _buildTileContent(
    BuildContext context,
    String startTimeStr,
    String endTimeStr,
    bool isAvailable,
    String patientCount,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatusIndicator(isAvailable),
          const SizedBox(width: 16),
          _buildTimeInfo(context, startTimeStr, endTimeStr),
          _buildBookingInfo(context, isAvailable, patientCount),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(bool isAvailable) {
    return Container(
      width: 8,
      height: 70,
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildTimeInfo(
    BuildContext context,
    String startTimeStr,
    String endTimeStr,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$startTimeStr - $endTimeStr",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Duration: ${timeSlot.duration.inMinutes} min",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfo(
    BuildContext context,
    bool isAvailable,
    String patientCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isAvailable ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isAvailable ? Colors.green : Colors.red),
          ),
          child: Text(
            isAvailable ? "Available" : "Fully Booked",
            style: TextStyle(
              color: isAvailable ? Colors.green[800] : Colors.red[800],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Patients: $patientCount",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
