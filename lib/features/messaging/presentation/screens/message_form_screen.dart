import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../providers/messaging_notifier.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../../patient/presentation/providers/patient_notifier.dart';

class MessageFormScreen extends ConsumerStatefulWidget {
  final Patient? preselectedPatient;

  const MessageFormScreen({super.key, this.preselectedPatient});

  @override
  ConsumerState<MessageFormScreen> createState() => _MessageFormScreenState();
}

class _MessageFormScreenState extends ConsumerState<MessageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isArabic = false;
  bool _isTest = false;
  String? _selectedPatientId;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPatient != null) {
      _phoneController.text = widget.preselectedPatient!.phone;
      _selectedPatientId = widget.preselectedPatient!.id;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagingState = ref.watch(messagingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send SMS Message'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRecipientSection(),
              const SizedBox(height: 16),
              _buildMessageContent(),
              const SizedBox(height: 16),
              _buildOptions(),
              const SizedBox(height: 24),

              if (messagingState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          messagingState.error!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  text: 'Send Message',
                  icon: Icons.send,
                  isLoading: messagingState.isSending,
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientSection() {
    final patientState = ref.watch(patientNotifierProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recipient', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g., 96599220322',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a phone number';
              }
              if (value.length < 8) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          if (!patientState.isLoading)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Patient',
                hintText: 'Select a patient (optional)',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              value: _selectedPatientId,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ...patientState.patients
                    .where((p) => p.status == PatientStatus.active)
                    .map(
                      (patient) => DropdownMenuItem<String>(
                        value: patient.id,
                        child: Text('${patient.name} (${patient.phone})'),
                      ),
                    )
                    ,
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPatientId = value;
                  if (value != null) {
                    final selectedPatient = patientState.patients.firstWhere(
                      (p) => p.id == value,
                    );
                    _phoneController.text = selectedPatient.phone;
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message Content',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Enter your message here',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: 160, // Standard SMS length
            textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a message';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Characters: ${_messageController.text.length}/160',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Options', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Arabic Language'),
            subtitle: const Text('Enable for Arabic messages'),
            value: _isArabic,
            onChanged: (value) {
              setState(() {
                _isArabic = value;
              });
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Test Mode'),
            subtitle: const Text('Message won\'t be sent but will be queued'),
            value: _isTest,
            onChanged: (value) {
              setState(() {
                _isTest = value;
              });
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final success = await ref
        .read(messagingProvider.notifier)
        .sendMessage(
          phoneNumber: _phoneController.text,
          message: _messageController.text,
          languageCode:
              _isArabic ? 3 : 1, // 1 for English, 3 for Arabic (UTF-8)
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }
}
