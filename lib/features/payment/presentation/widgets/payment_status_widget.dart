// lib/features/payment/presentation/widgets/payment_status_widget.dart
import 'package:flutter/material.dart';
import '../../domain/entities/payment_status.dart';

class PaymentStatusWidget extends StatelessWidget {
  final PaymentStatus? status;
  
  const PaymentStatusWidget({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return const SizedBox.shrink();
    }
    
    // Determine status color and text
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status!.status) {
      case PaymentStatusType.successful:
        statusColor = Colors.green;
        statusText = 'Payment Successful';
        statusIcon = Icons.check_circle;
        break;
      case PaymentStatusType.pending:
        statusColor = Colors.orange;
        statusText = 'Payment Pending';
        statusIcon = Icons.pending;
        break;
      case PaymentStatusType.processing:
        statusColor = Colors.blue;
        statusText = 'Payment Processing';
        statusIcon = Icons.sync;
        break;
      case PaymentStatusType.failed:
        statusColor = Colors.red;
        statusText = 'Payment Failed';
        statusIcon = Icons.cancel;
        break;
      case PaymentStatusType.refunded:
        statusColor = Colors.purple;
        statusText = 'Payment Refunded';
        statusIcon = Icons.replay;
        break;
      case PaymentStatusType.partiallyRefunded:
        statusColor = Colors.purple;
        statusText = 'Partially Refunded';
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown Status';
        statusIcon = Icons.help_outline;
    }
    
    // If there's an error message, show it
    final errorMessage = status!.errorMessage;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ],
          if (status!.transactionId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${status!.transactionId}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          if (status!.amount != null) ...[
            const SizedBox(height: 4),
            Text(
              'Amount: ${status!.amount!.toStringAsFixed(3)} ${status!.currency ?? ""}',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ],
          if (status!.timestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              'Date: ${status!.timestamp!.day}/${status!.timestamp!.month}/${status!.timestamp!.year}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}