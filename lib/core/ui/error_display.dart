// lib/core/ui/error_display.dart
import 'package:flutter/material.dart';
import '../utils/result.dart';

class ErrorDisplay {
  // Show a snackbar for an error
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Show a snackbar for success
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show an error dialog for critical errors
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Process a Result and show appropriate UI feedback
  static void handleResult<T>({
    required BuildContext context,
    required Result<T> result,
    String? successMessage,
    VoidCallback? onSuccess,
  }) {
    result.when(
      success: (data) {
        if (successMessage != null) {
          showSuccess(context, successMessage);
        }
        if (onSuccess != null) {
          onSuccess();
        }
      },
      failure: (error) {
        showError(context, error);
      },
    );
  }
}
