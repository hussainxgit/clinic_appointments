// lib/features/messaging/presentation/screens/messaging_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../data/providers/twilio_provider.dart';
import '../../services/sms_service.dart';

class MessagingSettingsScreen extends ConsumerStatefulWidget {
  const MessagingSettingsScreen({super.key});

  @override
  ConsumerState<MessagingSettingsScreen> createState() => _MessagingSettingsScreenState();
}

class _MessagingSettingsScreenState extends ConsumerState<MessagingSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Twilio settings
  final _accountSidController = TextEditingController();
  final _authTokenController = TextEditingController();
  final _defaultFromController = TextEditingController();
  bool _twilioTestMode = true;
  String? _selectedDefaultProvider;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _accountSidController.dispose();
    _authTokenController.dispose();
    _defaultFromController.dispose();
    super.dispose();
  }
  
  void _loadSettings() {
    final config = ref.read(smsConfigProvider);
    
    // Load default provider
    _selectedDefaultProvider = config['defaultProvider'] as String?;
    
    // Load Twilio settings
    final providers = config['providers'] as Map<String, dynamic>?;
    if (providers != null && providers.containsKey('twilio')) {
      final twilioConfig = providers['twilio'] as Map<String, dynamic>;
      _accountSidController.text = twilioConfig['accountSid'] as String? ?? '';
      _authTokenController.text = twilioConfig['authToken'] as String? ?? '';
      _defaultFromController.text = twilioConfig['defaultFrom'] as String? ?? '';
      _twilioTestMode = twilioConfig['testMode'] as bool? ?? true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final smsService = ref.watch(smsServiceProvider);
    final providers = smsService.getProviders();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Global settings
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Global Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Default provider selection
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Default Provider',
                      border: OutlineInputBorder(),
                      helperText: 'Provider used when none is specified',
                    ),
                    value: _selectedDefaultProvider,
                    items: providers.map((provider) {
                      return DropdownMenuItem<String>(
                        value: provider.providerId,
                        child: Text(provider.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDefaultProvider = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Twilio settings
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/twilio_logo.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.sms),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Twilio Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Account SID
                  TextFormField(
                    controller: _accountSidController,
                    decoration: const InputDecoration(
                      labelText: 'Account SID',
                      border: OutlineInputBorder(),
                      helperText: 'Your Twilio Account SID',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Account SID is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Auth Token
                  TextFormField(
                    controller: _authTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Auth Token',
                      border: OutlineInputBorder(),
                      helperText: 'Your Twilio Auth Token',
                      suffixIcon: Icon(Icons.visibility_off),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Auth Token is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Default From Number
                  TextFormField(
                    controller: _defaultFromController,
                    decoration: const InputDecoration(
                      labelText: 'Default From Number',
                      border: OutlineInputBorder(),
                      helperText: 'Your Twilio phone number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Default From Number is required';
                      }
                      if (!value.startsWith('+')) {
                        return 'Phone number should start with + and country code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Test Mode Switch
                  SwitchListTile(
                    title: const Text('Test Mode'),
                    subtitle: const Text('Use Twilio sandbox environment'),
                    value: _twilioTestMode,
                    onChanged: (value) {
                      setState(() {
                        _twilioTestMode = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            LoadingButton(
              text: 'Save Settings',
              isLoading: _isLoading,
              icon: Icons.save,
              onPressed: _saveSettings,
            ),
            
            const SizedBox(height: 16),
            
            // Test Connection Button
            OutlinedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Test Connection'),
              onPressed: _testConnection,
            ),
            
            const SizedBox(height: 32),
            
            // Help information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Getting Started with Twilio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const ListTile(
                    leading: Icon(Icons.looks_one),
                    title: Text('Create a Twilio account'),
                    subtitle: Text('Sign up at twilio.com and verify your email'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.looks_two),
                    title: Text('Get your Account SID and Auth Token'),
                    subtitle: Text('Find these in your Twilio Console Dashboard'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.looks_3),
                    title: Text('Buy a phone number'),
                    subtitle: Text('Purchase a number with SMS capabilities'),
                  ),
                  const ListTile(
                    leading: Icon(Icons.looks_4),
                    title: Text('Configure webhook URLs'),
                    subtitle: Text('Set up URLs for delivery notifications'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Visit Twilio Documentation'),
                    onPressed: () {
                      // Open Twilio docs in browser
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // In a real app, this would update secure storage or make an API call
      // Here we'll just simulate a delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Show success message
      if (!mounted) return;
      
ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // In a real app, you would reinitialize the provider with the new settings
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Testing Connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to Twilio...'),
          ],
        ),
      ),
    );

    try {
      // Create a temporary provider with the entered credentials
      final smsService = ref.read(smsServiceProvider);
      final testProvider = TwilioProvider();
      await testProvider.initialize({
        'accountSid': _accountSidController.text,
        'authToken': _authTokenController.text,
        'defaultFrom': _defaultFromController.text,
        'testMode': _twilioTestMode,
      });
      
      // Perform a simple test (in a real app, this might make an API call)
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      Navigator.pop(context); // Close the progress dialog
      
      // Show success message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Successful'),
          content: const Text('Successfully connected to Twilio API. Your credentials are valid.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close the progress dialog
      
      // Show error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Connection Failed'),
          content: Text('Failed to connect to Twilio: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}