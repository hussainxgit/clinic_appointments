import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:clinic_appointments/features/appointment_slot/models/appointment_slot.dart';
import 'package:clinic_appointments/features/doctor/models/doctor.dart';

class SlotListItem extends StatelessWidget {
  final AppointmentSlot slot;
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  const SlotListItem({
    super.key,
    required this.slot,
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final bookingPercentage = (slot.bookedPatients / slot.maxPatients) * 100;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getStatusColor(slot).withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _getStatusIcon(slot),
                      color: _getStatusColor(slot),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.date.dateOnly(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slot.date.dateOnly(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusIndicator(slot),
                      const SizedBox(height: 4),
                      Text(
                        'Dr. ${doctor.name}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: slot.bookedPatients / slot.maxPatients,
                  backgroundColor: Colors.grey.shade200,
                  color: _getProgressColor(bookingPercentage),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${slot.bookedPatients}/${slot.maxPatients} booked',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.work_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        doctor.specialty,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: Theme.of(context).primaryColor,
                        onPressed: onEdit,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: onDelete,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(AppointmentSlot slot) {
    final String statusText = _getStatusText(slot);
    final Color statusColor = _getStatusColor(slot);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getStatusText(AppointmentSlot slot) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime slotDate = DateTime(slot.date.year, slot.date.month, slot.date.day);

    if (slotDate.isBefore(today)) {
      return 'Past';
    } else if (slot.isFullyBooked) {
      return 'Fully Booked';
    } else if (slot.bookedPatients > 0) {
      return 'Partially Booked';
    } else if (slotDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else {
      return 'Available';
    }
  }

  Color _getStatusColor(AppointmentSlot slot) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime slotDate = DateTime(slot.date.year, slot.date.month, slot.date.day);

    if (slotDate.isBefore(today)) {
      return Colors.grey;
    } else if (slot.isFullyBooked) {
      return Colors.red;
    } else if (slot.bookedPatients > 0) {
      return Colors.orange;
    } else if (slotDate.isAtSameMomentAs(today)) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }

  IconData _getStatusIcon(AppointmentSlot slot) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime slotDate = DateTime(slot.date.year, slot.date.month, slot.date.day);

    if (slotDate.isBefore(today)) {
      return Icons.history;
    } else if (slot.isFullyBooked) {
      return Icons.event_busy;
    } else if (slot.bookedPatients > 0) {
      return Icons.event_available;
    } else if (slotDate.isAtSameMomentAs(today)) {
      return Icons.today;
    } else {
      return Icons.event;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) {
      return Colors.red;
    } else if (percentage >= 50) {
      return Colors.orange;
    } else if (percentage > 0) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
}