// lib/features/settings/view/about_screen.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appName = '';
  String _packageName = '';
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  Future<void> _getPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _appName = info.appName;
      _packageName = info.packageName;
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/app_logo.png',
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.medical_services,
                    size: 120,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
            
            // App Name and Version
            Center(
              child: Column(
                children: [
                  Text(
                    _appName.isEmpty ? 'Eye Clinic Appointments' : _appName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $_version ($_buildNumber)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // App Description
            const Text(
              'About the App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This Eye Clinic Appointment Management System helps streamline the process of scheduling and managing patient appointments, '
              'doctor availability, and clinical resources. It provides a comprehensive solution for both staff and patients.',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Key Features
            const Text(
              'Key Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem('Appointment scheduling and management'),
            _buildFeatureItem('Patient records and history'),
            _buildFeatureItem('Doctor availability tracking'),
            _buildFeatureItem('Cloud synchronization with Firebase'),
            _buildFeatureItem('Data analytics and reporting'),
            
            const SizedBox(height: 24),
            
            // Developer Info
            const Text(
              'Developed By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Company Name\ncontact@yourcompany.com',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 32),
            
            // Copyright
            Center(
              child: Text(
                '© ${DateTime.now().year} Your Company Name. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}