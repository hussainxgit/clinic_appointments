import 'package:flutter/material.dart';
import '../../../shared/utilities/utility.dart';
import '../../doctor/models/doctor.dart';
import '../models/appointment_slot.dart';

class SlotCard extends StatelessWidget {
  final AppointmentSlot slot;
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onBook;
  final VoidCallback? onDelete;

  const SlotCard({
    super.key,
    required this.slot,
    required this.doctor,
    required this.onEdit,
    required this.onBook,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final capacity = slot.maxPatients;
    final booked = slot.bookedPatients;
    final available = capacity - booked;
    final isFullyBooked = slot.isFullyBooked;
    final isPast = slot.date.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Status indicator at the top
          Container(
            height: 6,
            color: _getStatusColor(context, isFullyBooked, isPast),
          ),
          
          InkWell(
            onTap: !isPast ? onBook : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                        child: Icon(
                          doctor.isAvailable ? Icons.medical_services_rounded : Icons.person_off_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              doctor.specialty,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(context, isFullyBooked, isPast),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Slot details
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          Icons.date_range_rounded,
                          'Date',
                          slot.date.dateOnly3(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          Icons.people_alt_rounded,
                          'Capacity',
                          '$booked/$capacity ${isFullyBooked ? "• Full" : ""}',
                          isFullyBooked ? Colors.red : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          Icons.check_circle_outline_rounded,
                          'Available',
                          '$available',
                          available > 0 ? Colors.green : null,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isPast) ...[
                        OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (onDelete != null && !isPast) ...[
                        OutlinedButton.icon(
                          onPressed: onDelete,
                          icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                          label: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      FilledButton.icon(
                        onPressed: !isPast && !isFullyBooked ? onBook : null,
                        icon: const Icon(Icons.calendar_month_rounded),
                        label: const Text('Book'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, 
    IconData icon, 
    String title, 
    String value, 
    [Color? valueColor]
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, bool isFullyBooked, bool isPast) {
    late final String label;
    late final Color color;

    if (isPast) {
      label = 'Past';
      color = Colors.grey;
    } else if (isFullyBooked) {
      label = 'Full';
      color = Theme.of(context).colorScheme.error;
    } else if (slot.bookedPatients > 0) {
      label = 'Partial';
      color = Theme.of(context).colorScheme.tertiary;
    } else {
      label = 'Empty';
      color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, bool isFullyBooked, bool isPast) {
    if (isPast) {
      return Colors.grey;
    } else if (isFullyBooked) {
      return Theme.of(context).colorScheme.error;
    } else if (slot.bookedPatients > 0) {
      return Theme.of(context).colorScheme.tertiary;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
}