import 'package:flutter/material.dart';

abstract class NotificationService {
  void showSuccess(String message);
  void showError(String message);
}

class SnackBarNotificationService implements NotificationService {
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  SnackBarNotificationService(this.messengerKey);

  @override
  void showSuccess(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void showError(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}