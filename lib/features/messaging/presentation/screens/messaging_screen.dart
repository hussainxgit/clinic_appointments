import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../providers/messaging_notifier.dart';
import 'message_form_screen.dart';
import 'package:intl/intl.dart';

class MessagingScreen extends ConsumerStatefulWidget {
  const MessagingScreen({super.key});

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagingProvider.notifier).loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagingState = ref.watch(messagingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () => ref.read(messagingProvider.notifier).loadMessages(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToMessageForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child:
                messagingState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : messagingState.messages.isEmpty
                    ? EmptyState(
                      message: 'No messages yet',
                      icon: Icons.message,
                      actionLabel: 'Send New Message',
                      onAction: () => _navigateToMessageForm(context),
                    )
                    : _buildMessageList(messagingState.messages),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SMS Messaging',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Send SMS messages to patients, staff, or other contacts.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LoadingButton(
                    text: 'Send New Message',
                    icon: Icons.send,
                    onPressed: () => _navigateToMessageForm(context),
                    isLoading: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(List<dynamic> messages) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 16.0),
          onTap: () => _showMessageDetails(context, message),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'To: ${message.recipient}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(message.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                dateFormat.format(message.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'sent':
        color = Colors.green;
        label = 'SENT';
        break;
      case 'pending':
        color = Colors.orange;
        label = 'PENDING';
        break;
      case 'failed':
        color = Colors.red;
        label = 'FAILED';
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _navigateToMessageForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MessageFormScreen()),
    );
  }

  void _showMessageDetails(BuildContext context, dynamic message) {
    final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Message Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  _buildStatusChip(message.status),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Recipient', message.recipient),
              _buildDetailItem('Sent via', message.sender),
              _buildDetailItem('Date', dateFormat.format(message.createdAt)),
              if (message.messageId != null)
                _buildDetailItem('Message ID', message.messageId!),
              const SizedBox(height: 16),
              const Text(
                'Message Content',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message.message),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
