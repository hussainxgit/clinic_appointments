// lib/features/messaging/presentation/screens/template_message_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../data/providers/twilio_provider.dart';
import '../../data/templates/twilio_templates.dart';
import '../../domain/entities/sms_message.dart';
import '../../domain/entities/sms_template.dart';
import '../../services/sms_service.dart';

class TemplateMessageScreen extends ConsumerStatefulWidget {
  const TemplateMessageScreen({super.key});

  @override
  ConsumerState<TemplateMessageScreen> createState() =>
      _TemplateMessageScreenState();
}

class _TemplateMessageScreenState extends ConsumerState<TemplateMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final List<TextEditingController> _placeholderControllers = [];
  SmsTemplate? _selectedTemplate;
  bool _isWhatsApp = true; // Default to WhatsApp for templates
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get phone from arguments if available
    final phone = ModalRoute.of(context)?.settings.arguments as String?;
    if (phone != null && _toController.text.isEmpty) {
      _toController.text = phone;
    }
  }

  @override
  void dispose() {
    _toController.dispose();
    for (var controller in _placeholderControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _resetPlaceholderControllers() {
    // Clear old controllers
    for (var controller in _placeholderControllers) {
      controller.dispose();
    }
    _placeholderControllers.clear();

    // Create new controllers for the selected template
    if (_selectedTemplate != null) {
      for (var i = 0; i < _selectedTemplate!.placeholders.length; i++) {
        _placeholderControllers.add(TextEditingController());
      }
    }
  }
  // In lib/features/messaging/presentation/screens/messaging_screen.dart
  // And also in lib/features/messaging/presentation/screens/template_message_screen.dart

  @override
  void initState() {
    super.initState();

    // Make sure Twilio is registered
    final smsService = ref.read(smsServiceProvider);
    if (smsService.getProviders().isEmpty) {
      final twilio = TwilioProvider();
      final config = ref.read(smsConfigProvider);
      final twilioConfig =
          (config['providers'] as Map<String, dynamic>)['twilio'];
      twilio.initialize(twilioConfig);
      smsService.registerProvider(twilio);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = TwilioTemplates.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Template Message'),
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
                      'New Template Message',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildTemplateDropdown(templates),
                    if (_selectedTemplate != null) ...[
                      const SizedBox(height: 16),
                      _buildRecipientField(),
                      const SizedBox(height: 16),
                      _buildChannelToggle(),
                      const SizedBox(height: 16),
                      ..._buildPlaceholderFields(),
                      const SizedBox(height: 16),
                      _buildPreview(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: LoadingButton(
                          text: 'Send Template Message',
                          isLoading: _isLoading,
                          icon: Icons.send,
                          onPressed: _sendTemplateMessage,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (_errorMessage != null || _successMessage != null) ...[
                const SizedBox(height: 16),
                _buildStatusMessage(),
              ],

              const SizedBox(height: 24),
              _buildTemplateInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateDropdown(List<SmsTemplate> templates) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Template',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
      ),
      value: _selectedTemplate?.id,
      items:
          templates.map((template) {
            return DropdownMenuItem<String>(
              value: template.id,
              child: Text(template.description ?? template.id),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTemplate = TwilioTemplates.getById(value);
            _resetPlaceholderControllers();
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a message template';
        }
        return null;
      },
    );
  }

  Widget _buildRecipientField() {
    return TextFormField(
      controller: _toController,
      decoration: InputDecoration(
        labelText: _isWhatsApp ? 'WhatsApp Number' : 'Phone Number',
        hintText: 'Enter recipient number with country code',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(_isWhatsApp ? Icons.sms : Icons.phone),
        helperText: 'Include country code (e.g., +1 for USA)',
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a recipient number';
        }
        // Basic validation - should be replaced with proper phone validation
        if (!value.startsWith('+')) {
          return 'Phone number should start with + and country code';
        }
        return null;
      },
    );
  }

  Widget _buildChannelToggle() {
    return Row(
      children: [
        const Text('Channel:'),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Row(
            children: [
              Icon(Icons.sms, size: 16),
              SizedBox(width: 4),
              Text('WhatsApp'),
            ],
          ),
          selected: _isWhatsApp,
          onSelected: (selected) {
            setState(() {
              _isWhatsApp = selected;
            });
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Row(
            children: [
              Icon(Icons.sms, size: 16),
              SizedBox(width: 4),
              Text('SMS'),
            ],
          ),
          selected: !_isWhatsApp,
          onSelected: (selected) {
            setState(() {
              _isWhatsApp = !selected;
            });
          },
        ),
      ],
    );
  }

  List<Widget> _buildPlaceholderFields() {
    final widgets = <Widget>[];

    if (_selectedTemplate == null) return widgets;

    for (var i = 0; i < _selectedTemplate!.placeholders.length; i++) {
      final placeholder = _selectedTemplate!.placeholders[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            controller: _placeholderControllers[i],
            decoration: InputDecoration(
              labelText: 'Value for $placeholder',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.edit),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value for $placeholder';
              }
              return null;
            },
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildPreview() {
    if (_selectedTemplate == null) return const SizedBox.shrink();

    // Get values from controllers
    final values = _placeholderControllers.map((c) => c.text).toList();

    // If any value is empty, use the placeholder
    for (var i = 0; i < values.length; i++) {
      if (values[i].isEmpty) {
        values[i] = _selectedTemplate!.placeholders[i];
      }
    }

    // Format the template
    String previewText;
    try {
      previewText = _selectedTemplate!.format(values);
    } catch (e) {
      previewText = 'Preview error: ${e.toString()}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message Preview:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(previewText),
        ),
      ],
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

  Widget _buildTemplateInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About WhatsApp Business Templates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'WhatsApp business accounts require approved message templates for initial outreach. '
            'Once a user responds, you can send free-form messages for the next 24 hours.',
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Pre-approved templates'),
            subtitle: Text('Templates must be pre-approved by WhatsApp'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Placeholder variables'),
            subtitle: Text(
              'Use the provided fields to fill in template variables',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('24-hour window'),
            subtitle: Text(
              'After a user responds, you can send regular messages for 24 hours',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTemplateMessage() async {
    // Clear previous messages
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate() || _selectedTemplate == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final smsService = ref.read(smsServiceProvider);

      // Get placeholder values
      final placeholderValues =
          _placeholderControllers.map((c) => c.text).toList();

      // Format the template
      final messageBody = _selectedTemplate!.format(placeholderValues);

      // For this example, we'll embed our important message into the verification code template
      // This is a way to "hack" around the template restriction while waiting for approval
      // Note: This is for demonstration - in a real app, you'd use properly approved templates

      final message = SmsMessage(
        to: _toController.text,
        from: '', // Will use default from provider
        body: messageBody,
        metadata: {
          'isWhatsApp': _isWhatsApp,
          'templateId': _selectedTemplate!.id,
          // In a real implementation, you'd include the template SID from Twilio
          // 'templateSid': 'YOUR_TEMPLATE_SID',
        },
      );

      final response = await smsService.sendSms(
        message,
        providerId: 'twilio', // Templates are specifically for Twilio
      );

      setState(() {
        _isLoading = false;

        if (response.success) {
          _successMessage =
              'Template message sent successfully! ID: ${response.messageId}';
          // Clear form on success
          if (!mounted) return;
          for (var controller in _placeholderControllers) {
            controller.clear();
          }
        } else {
          _errorMessage =
              'Failed to send template message: ${response.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error sending template message: ${e.toString()}';
      });
    }
  }
}
