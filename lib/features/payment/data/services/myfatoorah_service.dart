import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/payment_config.dart';
import '../models/payment_record.dart';
import '../../domain/entities/payment_response.dart';

class MyFatoorahService {
  final http.Client _httpClient;

  MyFatoorahService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  Future<PaymentResponse> createInvoiceLink({
    required String appointmentId,
    required String patientName,
    required String patientEmail,
    required String patientMobile,
    required double amount,
    String currency = 'KWD',
    String? customerReference,
    String language = 'en',
  }) async {
    try {
      final url = '${PaymentConfig.baseUrl}/v2/SendPayment';

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${PaymentConfig.apiKey}',
        },
        body: jsonEncode({
          'NotificationOption': 'LNK', // Return link only, don't send email/SMS
          'CustomerName': patientName,
          'DisplayCurrencyIso': currency,
          'MobileCountryCode': '+965', // Kuwait code, consider making dynamic
          'CustomerMobile': patientMobile,
          'CustomerEmail': patientEmail,
          'InvoiceValue': amount,
          'CallBackUrl': PaymentConfig.webhookUrl,
          'ErrorUrl': PaymentConfig.webhookUrl,
          'Language': language,
          'CustomerReference': customerReference ?? appointmentId,
          'InvoiceItems': [
            {
              'ItemName': 'Eye Clinic Appointment',
              'Quantity': 1,
              'UnitPrice': amount,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['IsSuccess'] == true) {
          final data = responseData['Data'];
          return PaymentResponse(
            success: true,
            invoiceId: data['InvoiceId'].toString(),
            invoiceUrl: data['InvoiceURL'],
            customerReference: data['CustomerReference'],
          );
        } else {
          final errorMsg =
              responseData['ValidationErrors']?[0]?['Error'] ??
              responseData['Message'] ??
              'Failed to create payment link';
          return PaymentResponse(success: false, errorMessage: errorMsg);
        }
      } else {
        return PaymentResponse(
          success: false,
          errorMessage: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PaymentResponse(
        success: false,
        errorMessage: 'Error creating payment link: $e',
      );
    }
  }

  Future<PaymentResponse> checkPaymentStatus(String invoiceId) async {
    try {
      final url = '${PaymentConfig.baseUrl}/v2/GetPaymentStatus';

      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${PaymentConfig.apiKey}',
        },
        body: jsonEncode({'Key': invoiceId, 'KeyType': 'InvoiceId'}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['IsSuccess'] == true) {
          final data = responseData['Data'];
          final invoiceStatus = data['InvoiceStatus'];
          final transactionId =
              data['InvoiceTransactions']?[0]?['TransactionId'];

          return PaymentResponse(
            success: true,
            invoiceId: invoiceId,
            status: _mapInvoiceStatus(invoiceStatus),
            transactionId: transactionId?.toString(),
            metadata: data,
          );
        } else {
          return PaymentResponse(
            success: false,
            errorMessage:
                responseData['Message'] ?? 'Failed to check payment status',
          );
        }
      } else {
        return PaymentResponse(
          success: false,
          errorMessage: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PaymentResponse(
        success: false,
        errorMessage: 'Error checking payment status: $e',
      );
    }
  }

  PaymentStatus _mapInvoiceStatus(String invoiceStatus) {
    switch (invoiceStatus.toLowerCase()) {
      case 'paid':
        return PaymentStatus.successful;
      case 'unpaid':
        return PaymentStatus.pending;
      case 'failed':
      case 'expired':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}
