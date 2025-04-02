// First, let's define color extension file to centralize our color definitions
// Create a new file at lib/core/ui/theme/app_colors.dart

import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Extension class for standardized application colors
class AppColors {
  // Primary colors from app_theme.dart
  static const Color primary = AppTheme.primaryColor; // Navy blue
  static const Color accent = AppTheme.accentColor; // Blue accent

  // Background colors
  static const Color background = AppTheme.backgroundColor;
  static const Color cardBackground = Colors.white;
  static const Color secondaryBackground = Color(0xFFF8F9FA);

  // Text colors
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textOnPrimary = Colors.white;

  // Status colors (maintain semantic meaning but with app-specific hues)
  static final Color success = AppTheme.successColor; // Green
  static final Color error = AppTheme.errorColor; // Red
  static final Color warning = AppTheme.warningColor; // Orange/amber
  static final Color info = AppTheme.infoColor; // Light blue

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0E0E48), Color(0xFF14146C)], // Darker to lighter navy
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF4285F4), Color(0xFF5B9BFF)], // Accent variations
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
