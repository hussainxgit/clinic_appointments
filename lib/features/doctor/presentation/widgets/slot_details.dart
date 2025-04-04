import 'package:flutter/material.dart';
import '../../../../features/appointment_slot/domain/entities/appointment_slot.dart';
import 'time_slot_tile.dart';

class SlotDetails extends StatelessWidget {
  final AppointmentSlot daySlot;

  const SlotDetails({super.key, required this.daySlot});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSlotStats(),
        const SizedBox(height: 8),
        _buildTimeSlotsLineIndicator(),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          itemCount: daySlot.timeSlots.length,
          itemBuilder:
              (context, index) => TimeSlotTile(
                slot: daySlot,
                timeSlot: daySlot.timeSlots[index],
              ),
        ),
      ],
    );
  }

  Widget _buildSlotStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.person,
          label: 'Total Booked',
          value: daySlot.totalBookedPatients.toString(),
        ),
        _buildStatItem(
          icon: Icons.event_available,
          label: 'Time Slots',
          value: daySlot.timeSlots.length.toString(),
        ),
        _buildStatItem(
          icon: !daySlot.isFullyBooked ? Icons.check_circle : Icons.cancel,
          label: 'Status',
          value: !daySlot.isFullyBooked ? 'Available' : 'Fully Booked',
          color: !daySlot.isFullyBooked ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildTimeSlotsLineIndicator() {
    final bookedSlots =
        daySlot.timeSlots.where((slot) => slot.isFullyBooked).length;

    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: bookedSlots / daySlot.timeSlots.length,
            backgroundColor: Colors.grey[200],
            color: _getAvailabilityColor(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
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

  Color _getAvailabilityColor() {
    if (daySlot.isFullyBooked) {
      return Colors.red;
    } else if (daySlot.hasBookedPatients) {
      return Colors.orange;
    }
    return Colors.green;
  }
}
