// lib/core/utils/error_handler.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'result.dart';

class ErrorHandler {
  // Convert any exception to a Result.failure with appropriate message
  static Result<T> handle<T>(dynamic error, [String? operation]) {
    // Log the error for debugging purposes
    _logError(error, operation);
    
    // Handle specific exception types
    if (error is FirebaseException) {
      return Result.failure(_handleFirebaseException(error));
    } else if (error is FirebaseAuthException) {
      return Result.failure(_handleAuthException(error));
    } else if (error is SocketException) {
      return Result.failure('Network error: Please check your connection');
    } else if (error is HttpException) {
      return Result.failure('Server error: ${error.message}');
    } else if (error is FormatException) {
      return Result.failure('Data format error');
    } else if (error is TimeoutException) {
      return Result.failure('The operation timed out. Please try again');
    } else if (error is String) {
      return Result.failure(error);
    } else {
      // Generic error handling
      return Result.failure('An unexpected error occurred${operation != null ? ' while $operation' : ''}');
    }
  }

  // Handle Firebase exceptions
  static String _handleFirebaseException(FirebaseException exception) {
    switch (exception.code) {
      case 'permission-denied':
        return 'You don\'t have permission to access this resource';
      case 'not-found':
        return 'The requested resource was not found';
      case 'already-exists':
        return 'This record already exists';
      case 'unavailable':
        return 'The service is currently unavailable. Please try again later';
      case 'failed-precondition':
        return 'Operation cannot be performed in the current state';
      default:
        return exception.message ?? 'A database error occurred';
    }
  }

  // Handle Authentication exceptions
  static String _handleAuthException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'The password is too weak';
      case 'invalid-email':
        return 'Invalid email format';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return exception.message ?? 'An authentication error occurred';
    }
  }

  // Log the error for debugging
  static void _logError(dynamic error, String? operation) {
    final message = operation != null 
        ? 'Error $operation: $error'
        : 'Error: $error';
    
    // Add your preferred logging implementation here
    print(message);
    
    // In a real app, you might want to log to a service like Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
  }
  
  // Utility method to wrap async operations in a Result
  static Future<Result<T>> guardAsync<T>(
    Future<T> Function() operation, 
    [String? operationName]
  ) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (e) {
      return handle<T>(e, operationName);
    }
  }
}