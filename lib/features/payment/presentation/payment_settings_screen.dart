// lib/features/payment/presentation/screens/payment_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/payment_service.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Text controllers for the form
  final _myFatoorahApiKeyController = TextEditingController();
  final _tapApiKeyController = TextEditingController();
  final _tapSecretKeyController = TextEditingController();
  
  // Toggle values
  bool _myFatoorahTestMode = true;
  bool _tapTestMode = true;
  bool _enableTapToPay = true;
  
  @override
  void initState() {
    super.initState();
    // Load current settings
    _loadSettings();
  }
  
  @override
  void dispose() {
    _myFatoorahApiKeyController.dispose();
    _tapApiKeyController.dispose();
    _tapSecretKeyController.dispose();
    super.dispose();
  }
  
  void _loadSettings() {
    // In a real app, this would load from secure storage
    // For this example, we're just using the values from the provider
    final config = ref.read(paymentConfigProvider);
    
    // MyFatoorah settings
    final myFatoorahConfig = config['gateways']['myfatoorah'] as Map<String, dynamic>;
    _myFatoorahApiKeyController.text = myFatoorahConfig['apiKey'] as String;
    _myFatoorahTestMode = myFatoorahConfig['testMode'] as bool? ?? true;
    
    // Tap settings
    final tapConfig = config['gateways']['tap'] as Map<String, dynamic>;
    _tapApiKeyController.text = tapConfig['apiKey'] as String;
    _tapSecretKeyController.text = tapConfig['secretKey'] as String;
    _tapTestMode = tapConfig['testMode'] as bool? ?? true;
    
    // Tap to Pay settings
    final tapToPayConfig = config['gateways']['tap_to_pay'] as Map<String, dynamic>;
    _enableTapToPay = tapToPayConfig['testMode'] as bool? ?? true;
  }
  
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // In a real app, this would save to secure storage
    // and potentially update the provider or restart services
    
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Settings'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // MyFatoorah Settings
            _buildSectionHeader('MyFatoorah Settings'),
            _buildApiKeyField(
              controller: _myFatoorahApiKeyController,
              label: 'MyFatoorah API Key',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter API Key';
                }
                return null;
              },
            ),
            _buildToggleRow(
              title: 'Test Mode',
              subtitle: 'Use MyFatoorah sandbox environment',
              value: _myFatoorahTestMode,
              onChanged: (value) {
                setState(() {
                  _myFatoorahTestMode = value;
                });
              },
            ),
            const Divider(height: 32),
            
            // Tap Settings
            _buildSectionHeader('Tap Payments Settings'),
            _buildApiKeyField(
              controller: _tapApiKeyController,
              label: 'Tap API Key',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter API Key';
                }
                return null;
              },
            ),
            _buildApiKeyField(
              controller: _tapSecretKeyController,
              label: 'Tap Secret Key',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter Secret Key';
                }
                return null;
              },
            ),
            _buildToggleRow(
              title: 'Test Mode',
              subtitle: 'Use Tap sandbox environment',
              value: _tapTestMode,
              onChanged: (value) {
                setState(() {
                  _tapTestMode = value;
                });
              },
            ),
            const Divider(height: 32),
            
            // Tap to Pay Settings
            _buildSectionHeader('In-Person Payments'),
            _buildToggleRow(
              title: 'Enable Tap to Pay',
              subtitle: 'Allow in-person payments via card reader',
              value: _enableTapToPay,
              onChanged: (value) {
                setState(() {
                  _enableTapToPay = value;
                });
              },
            ),
            const SizedBox(height: 32),
            
            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildApiKeyField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              // Toggle visibility (in a real app)
            },
          ),
        ),
        obscureText: true,
        validator: validator,
      ),
    );
  }
  
  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}