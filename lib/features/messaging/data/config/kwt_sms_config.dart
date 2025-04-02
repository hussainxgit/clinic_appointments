// This file contains configuration for the KWT SMS API
// For production, these values should be loaded from secure storage or environment variables

import 'package:flutter_dotenv/flutter_dotenv.dart';

class KwtSmsConfig {
  // API credentials
  static String apiUsername =
      dotenv.env['KWT_SMS_USERNAME'] ?? ''; // API username
  static String apiPassword =
      dotenv.env['KWT_SMS_PASSWORD'] ?? ''; // API password

  // Sender ID (11 characters max, case-sensitive)
  static const String defaultSenderId = 'KWT-SMS';

  // Language codes
  static const int englishLanguage = 1; // English
  static const int arabicCP1256 = 2; // Arabic (CP1256)
  static const int arabicUTF8 = 3; // Arabic (UTF-8)
  static const int unicode = 4; // Unicode

  // API endpoints
  static const String sendEndpoint = 'https://www.kwtsms.com/API/send/';

  // Message templates
  static String appointmentReminderTemplate(
    String patientName,
    String appointmentDate,
    String doctorName,
  ) {
    return 'Dear $patientName, this is a reminder for your appointment on $appointmentDate with Dr. $doctorName. Please confirm by replying YES or call to reschedule.';
  }

  static String appointmentConfirmationTemplate(
    String patientName,
    String appointmentDate,
    String doctorName,
  ) {
    return 'Dear $patientName, your appointment has been confirmed for $appointmentDate with Dr. $doctorName. Thank you for choosing Eye Clinic.';
  }
}
