// lib/features/payment/domain/entities/payment_response.dart
enum PaymentResponseType { redirect, widget, error }

class PaymentResponse {
  final PaymentResponseType type;
  final String paymentId;
  final String? redirectUrl;
  final Map<String, dynamic>? widgetData;
  final String? errorMessage;

  PaymentResponse.redirect({
    required this.paymentId,
    required this.redirectUrl,
  })  : type = PaymentResponseType.redirect,
        widgetData = null,
        errorMessage = null;

  PaymentResponse.widget({
    required this.paymentId,
    required this.widgetData,
  })  : type = PaymentResponseType.widget,
        redirectUrl = null,
        errorMessage = null;

  PaymentResponse.error({
    required this.errorMessage,
  })  : type = PaymentResponseType.error,
        paymentId = '',
        redirectUrl = null,
        widgetData = null;

  bool get isSuccess => type != PaymentResponseType.error;
}
