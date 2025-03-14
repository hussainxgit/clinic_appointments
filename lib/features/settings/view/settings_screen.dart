// lib/features/settings/view/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _useFirebase = true;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Arabic', 'Spanish'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _useFirebase = prefs.getBool('useFirebase') ?? true;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setBool('useFirebase', _useFirebase);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // General Settings
          _buildSectionHeader('General Settings'),
          _buildSettingSwitch(
            'Dark Mode',
            'Switch between light and dark theme',
            Icons.brightness_6,
            _isDarkMode,
            (value) {
              setState(() {
                _isDarkMode = value;
                _saveSettings();
              });
              // Implement theme switching logic
            },
          ),
          _buildLanguageDropdown(),

          const Divider(),

          // Firebase Settings
          _buildSectionHeader('Cloud Settings'),
          _buildSettingSwitch(
            'Use Firebase',
            'Enable cloud synchronization with Firebase',
            Icons.cloud,
            _useFirebase,
            (value) {
              setState(() {
                _useFirebase = value;
                _saveSettings();
              });
            },
          ),
          _buildNavigationTile(
              'Firebase Settings',
              'Configure cloud synchronization and data management',
              Icons.settings_applications,
              () => {}),

          const Divider(),

          // Notification Settings
          _buildSectionHeader('Notifications'),
          _buildSettingSwitch(
            'Enable Notifications',
            'Receive alerts for appointments and updates',
            Icons.notifications,
            _notificationsEnabled,
            (value) {
              setState(() {
                _notificationsEnabled = value;
                _saveSettings();
              });
            },
          ),

          const Divider(),

          // App Info
          _buildSectionHeader('Application'),
          _buildNavigationTile(
            'About',
            'App version and information',
            Icons.info_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AboutScreen(),
              ),
            ),
          ),
          _buildNavigationTile(
            'Terms & Privacy Policy',
            'Review our terms of service',
            Icons.description,
            () => _launchUrl('https://yourapp.com/privacy'),
          ),
          _buildNavigationTile(
            'Contact Support',
            'Get help with any issues',
            Icons.help_outline,
            () => _launchUrl('mailto:support@yourapp.com'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildNavigationTile(
    String title,
    String subtitle,
    IconData icon,
    Function() onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLanguageDropdown() {
    return ListTile(
      leading: const Icon(Icons.language, color: Colors.blue),
      title: const Text('Language'),
      subtitle: const Text('Select your preferred language'),
      trailing: DropdownButton<String>(
        value: _selectedLanguage,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedLanguage = newValue;
              _saveSettings();
            });
          }
        },
        items: _languages.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }
}
