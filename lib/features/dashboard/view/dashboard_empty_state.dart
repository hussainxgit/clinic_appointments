import 'package:flutter/material.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';

class DashboardEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const DashboardEmptyState({
    super.key,
    required this.message,
    required this.icon,
    required this.buttonText,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallScreen;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isSmall ? 48 : 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
                color: Colors.grey.shade600, fontSize: isSmall ? 16 : 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: onButtonPressed,
              child: Text(buttonText,
                  style: TextStyle(fontSize: isSmall ? 14 : 16))),
        ],
      ),
    );
  }
}