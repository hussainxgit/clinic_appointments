// lib/features/messaging/presentation/screens/messaging_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../domain/entities/sms_message.dart';
import '../../services/sms_service.dart';

class MessagingScreen extends ConsumerStatefulWidget {
  const MessagingScreen({super.key});

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _fromController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedProvider;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _toController.dispose();
    _fromController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final smsConfig = ref.watch(smsConfigProvider);
    final defaultProvider = smsConfig['defaultProvider'] as String? ?? 'twilio';

    if (_selectedProvider == null) {
      _selectedProvider = defaultProvider;

      // Set default from number if available
      final providers = smsConfig['providers'] as Map<String, dynamic>?;
      if (providers != null && providers.containsKey(defaultProvider)) {
        final providerConfig =
            providers[defaultProvider] as Map<String, dynamic>;
        if (providerConfig.containsKey('defaultFrom')) {
          _fromController.text = providerConfig['defaultFrom'];
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send SMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Message History',
            onPressed: () {
              ref
                  .read(navigationServiceProvider)
                  .navigateTo('/messaging/history');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Messaging Settings',
            onPressed: () {
              ref
                  .read(navigationServiceProvider)
                  .navigateTo('/messaging/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Message',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildProviderDropdown(),
                    const SizedBox(height: 16),
                    _buildRecipientField(),
                    const SizedBox(height: 16),
                    _buildSenderField(),
                    const SizedBox(height: 16),
                    _buildMessageField(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        text: 'Send Message',
                        isLoading: _isLoading,
                        icon: Icons.send,
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null || _successMessage != null) ...[
                const SizedBox(height: 16),
                _buildStatusMessage(),
              ],

              const SizedBox(height: 24),
              _buildMessagingTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderDropdown() {
    final smsService = ref.read(smsServiceProvider);
    final providers = smsService.getProviders();
    final providerIds = providers.map((p) => p.providerId).toList();

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'SMS Provider',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      value: _selectedProvider,
      items:
          providers.map((provider) {
            return DropdownMenuItem<String>(
              value: provider.providerId,
              child: Text(provider.displayName),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedProvider = value;

          // Update the from number based on the selected provider
          final smsConfig = ref.read(smsConfigProvider);
          final providerConfigs =
              smsConfig['providers'] as Map<String, dynamic>?;
          if (providerConfigs != null && providerConfigs.containsKey(value)) {
            final providerConfig =
                providerConfigs[value] as Map<String, dynamic>;
            if (providerConfig.containsKey('defaultFrom')) {
              _fromController.text = providerConfig['defaultFrom'];
            }
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty || !providerIds.contains(value)) {
          return 'Please select a valid SMS provider';
        }
        return null;
      },
    );
  }

  Widget _buildRecipientField() {
    return TextFormField(
      controller: _toController,
      decoration: const InputDecoration(
        labelText: 'To',
        hintText: 'Enter recipient phone number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a recipient phone number';
        }
        // Basic validation - should be replaced with proper phone validation
        if (!value.startsWith('+')) {
          return 'Phone number should start with + and country code';
        }
        return null;
      },
    );
  }

  Widget _buildSenderField() {
    return TextFormField(
      controller: _fromController,
      decoration: const InputDecoration(
        labelText: 'From (Optional)',
        hintText: 'Enter sender phone number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
        helperText: 'Leave empty to use provider default',
      ),
      keyboardType: TextInputType.phone,
      // From is optional as the provider might use a default
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      decoration: const InputDecoration(
        labelText: 'Message',
        hintText: 'Enter your message',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a message';
        }
        if (value.length > 160) {
          return 'Message exceeds 160 characters (${value.length}/160)';
        }
        return null;
      },
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _errorMessage != null ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              _errorMessage != null
                  ? Colors.red.shade200
                  : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _errorMessage != null ? Icons.error : Icons.check_circle,
            color: _errorMessage != null ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _errorMessage ?? _successMessage ?? '',
              style: TextStyle(
                color: _errorMessage != null ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagingTips() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tips for SMS Messaging',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Phone number format'),
            subtitle: Text(
              'Always include the country code with + prefix (e.g., +1 for USA)',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Message length'),
            subtitle: Text(
              'Keep messages under 160 characters to avoid splitting',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Scheduled messages'),
            subtitle: Text(
              'Schedule messages during business hours for better response rates',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final smsService = ref.read(smsServiceProvider);

      final message = SmsMessage(
        to: _toController.text,
        from: _fromController.text,
        body: _messageController.text,
      );

      final response = await smsService.sendSms(
        message,
        providerId: _selectedProvider,
      );

      setState(() {
        _isLoading = false;

        if (response.success) {
          _successMessage =
              'Message sent successfully! ID: ${response.messageId}';
          // Clear form on success
          if (!mounted) return;
          _messageController.clear();
        } else {
          _errorMessage = 'Failed to send message: ${response.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error sending message: ${e.toString()}';
      });
    }
  }
}
