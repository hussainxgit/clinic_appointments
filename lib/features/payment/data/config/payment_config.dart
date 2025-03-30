import '../../../../.my_secrets.dart';

class PaymentConfig {
  // MyFatoorah Configuration
  static const bool testMode = true;

  static String get apiKey =>
      testMode ? myfatoorahApiKey : myfatoorahProductionApiKey;

  static String get baseUrl =>
      testMode
          ? 'https://apitest.myfatoorah.com'
          : 'https://api.myfatoorah.com';

  static String get webhookUrl =>
      'https://myfatoorahwebhook-45g5y5hrca-uc.a.run.app';

  // Default payment settings
  static const String defaultCurrency = 'KWD';
  static const String language = 'en';

  // Payment amounts (could be moved to a database later)
  static const Map<String, double> serviceAmounts = {
    'consultation': 15.0,
    'followUp': 10.0,
    'procedure': 50.0,
    'test': 25.0,
  };

  // Payment message templates
  static String paymentMessageTemplate({
    required String patientName,
    required String appointmentDate,
    required String amount,
    required String paymentLink,
  }) {
    return '''Thank you $patientName for booking your appointment on $appointmentDate.

Please complete your payment of $amount $defaultCurrency through this secure link:
$paymentLink

The payment will be confirmed automatically.

Eye Clinic Team
''';
  }

  static String paymentConfirmationTemplate({
    required String patientName,
    required String appointmentDate,
    required String amount,
  }) {
    return '''Thank you $patientName! 

Your payment of $amount $defaultCurrency has been confirmed.
Your appointment on $appointmentDate is now confirmed.

We look forward to seeing you!

Eye Clinic Team
''';
  }
}
