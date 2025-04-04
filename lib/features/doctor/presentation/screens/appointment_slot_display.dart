import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/ui/theme/app_colors.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../appointment_slot/domain/entities/appointment_slot.dart';
import '../../../appointment_slot/domain/entities/time_slot.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';

class AppointmentSlotDisplay extends ConsumerWidget {
  final String doctorId;
  final DateTime selectedDate;
  final Function(AppointmentSlot, TimeSlot)? onTimeSlotSelected;
  final VoidCallback? onAddSlot;

  const AppointmentSlotDisplay({
    super.key,
    required this.doctorId,
    required this.selectedDate,
    this.onTimeSlotSelected,
    this.onAddSlot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsState = ref.watch(appointmentSlotNotifierProvider);

    if (slotsState.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final daySlots = _getFilteredDaySlots(slotsState);

    if (daySlots.isEmpty) {
      return EmptyState(
        message:
            "No appointment slots on ${DateFormat.yMMMMd().format(selectedDate)}",
        icon: Icons.event_busy,
        onAction: onAddSlot,
        actionLabel: onAddSlot != null ? "Add Slot" : null,
      );
    }

    return _buildSlotDetails(context, daySlots.first);
  }

  List<AppointmentSlot> _getFilteredDaySlots(AppointmentSlotState slotsState) {
    return slotsState.slots
        .where(
          (slot) =>
              slot.doctorId == doctorId &&
              _isSameDay(slot.date, selectedDate) &&
              slot.isActive,
        )
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSlotDetails(BuildContext context, AppointmentSlot slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SlotStats(slot: slot),
        const SizedBox(height: 8),
        _TimeSlotList(
          slot: slot,
          onTimeSlotTap:
              onTimeSlotSelected != null
                  ? (timeSlot) => onTimeSlotSelected!(slot, timeSlot)
                  : null,
        ),
      ],
    );
  }
}

class _SlotStats extends StatelessWidget {
  final AppointmentSlot slot;

  const _SlotStats({required this.slot});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.person,
              label: 'Total Booked',
              value: slot.totalBookedPatients.toString(),
            ),
            _StatItem(
              icon: Icons.event_available,
              label: 'Time Slots',
              value: slot.timeSlots.length.toString(),
            ),
            _StatItem(
              icon: !slot.isFullyBooked ? Icons.check_circle : Icons.cancel,
              label: 'Status',
              value: !slot.isFullyBooked ? 'Available' : 'Fully Booked',
              color: !slot.isFullyBooked ? Colors.green : Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _AvailabilityIndicator(slot: slot),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[700]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _AvailabilityIndicator extends StatelessWidget {
  final AppointmentSlot slot;

  const _AvailabilityIndicator({required this.slot});

  @override
  Widget build(BuildContext context) {
    final bookedSlots =
        slot.timeSlots.where((slot) => slot.isFullyBooked).length;

    return LinearProgressIndicator(
      value: bookedSlots / slot.timeSlots.length,
      backgroundColor: Colors.grey[200],
      color: _getAvailabilityColor(),
      minHeight: 6,
      borderRadius: BorderRadius.circular(3),
    );
  }

  Color _getAvailabilityColor() {
    if (slot.isFullyBooked) {
      return Colors.red;
    } else if (slot.hasBookedPatients) {
      return Colors.orange;
    }
    return Colors.green;
  }
}

class _TimeSlotList extends StatelessWidget {
  final AppointmentSlot slot;
  final Function(TimeSlot)? onTimeSlotTap;

  const _TimeSlotList({required this.slot, this.onTimeSlotTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: slot.timeSlots.length,
      itemBuilder:
          (context, index) => _TimeSlotTile(
            timeSlot: slot.timeSlots[index],
            onTap:
                onTimeSlotTap != null
                    ? () => onTimeSlotTap!(slot.timeSlots[index])
                    : null,
          ),
    );
  }
}

class _TimeSlotTile extends StatelessWidget {
  final TimeSlot timeSlot;
  final VoidCallback? onTap;

  const _TimeSlotTile({required this.timeSlot, this.onTap});

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
        onTap: isAvailable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 70,
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$startTimeStr - $endTimeStr",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Duration: ${timeSlot.duration.inMinutes} min",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Text(
                      isAvailable ? "Available" : "Fully Booked",
                      style: TextStyle(
                        color:
                            isAvailable ? Colors.green[800] : Colors.red[800],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
