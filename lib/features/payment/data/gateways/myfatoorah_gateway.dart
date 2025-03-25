// lib/features/payment/data/gateways/myfatoorah_gateway.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/interfaces/payment_gateway.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_response.dart';
import '../../domain/entities/payment_status.dart';

class MyFatoorahGateway implements PaymentGateway {
  static const String _sandboxBaseUrl = 'https://apitest.myfatoorah.com';
  static const String _productionBaseUrl = 'https://api.myfatoorah.com';
  // Set the callback URL to your deployed function
  final webhookUrl =
      "https://us-central1-eye-clinic-41214.cloudfunctions.net/myFatoorahWebhook";

  late String _baseUrl;
  late String _apiKey;
  late bool _isTestMode;

  @override
  String get gatewayId => 'myfatoorah';

  @override
  String get displayName => 'MyFatoorah';

  @override
  String get iconAsset => 'assets/images/payment/myfatoorah_logo.png';

  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    if (!config.containsKey('apiKey')) {
      throw Exception('API key is required');
    }
    _apiKey = config['apiKey'] as String;
    _isTestMode = config['testMode'] as bool? ?? true;
    _baseUrl = _isTestMode ? _sandboxBaseUrl : _productionBaseUrl;
  }

  Future<List<Map<String, dynamic>>> _initiatePayment(
    double amount,
    String currency,
  ) async {
    final url = '$_baseUrl/v2/InitiatePayment';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({'InvoiceAmount': amount, 'CurrencyIso': currency}),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode != 200 || responseData['IsSuccess'] != true) {
      final error =
          responseData['ValidationErrors']?[0]?['Error'] ??
          responseData['Message'] ??
          'Failed to initiate payment';
      throw Exception(error);
    }

    return List<Map<String, dynamic>>.from(
      responseData['Data']['PaymentMethods'],
    );
  }

  @override
  Future<PaymentResponse> createPayment(PaymentRequest request) async {
    try {
      // Get available payment methods
      final paymentMethods = await _initiatePayment(
        request.amount,
        request.currency,
      );

      // Filter for non-direct payment methods (as per Python implementation)
      final availableMethods =
          paymentMethods
              .where((method) => method['IsDirectPayment'] == false)
              .map(
                (method) => {
                  'PaymentMethodEn': method['PaymentMethodEn'],
                  'PaymentMethodId': method['PaymentMethodId'],
                },
              )
              .toList();

      if (availableMethods.isEmpty) {
        return PaymentResponse.error(
          errorMessage: 'No available payment methods',
        );
      }

      // Using first available payment method (in Python it was user-selected)
      // You might want to modify this to allow user selection
      final paymentMethodId = 1; // knet

      // Execute payment
      final url = '$_baseUrl/v2/ExecutePayment';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'PaymentMethodId': paymentMethodId,
          'InvoiceValue': request.amount,
          'CallBackUrl': request.callbackUrl ?? webhookUrl,
          'ErrorUrl': request.returnUrl ?? webhookUrl,
          'CustomerName': request.customerName,
          'CustomerEmail': request.customerEmail,
          'CustomerMobile': request.customerPhone,
          'Language': 'en',
          'CustomerReference': request.referenceId,
          'MobileCountryCode': '+965',
          'DisplayCurrencyIso': request.currency,
          'InvoiceItems': [
            {
              'ItemName': request.description ?? 'Payment',
              'Quantity': 1,
              'UnitPrice': request.amount,
            },
          ],
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['IsSuccess'] == true) {
        final invoiceId = responseData['Data']['InvoiceId'].toString();
        final paymentUrl = responseData['Data']['PaymentURL'];

        return PaymentResponse.redirect(
          paymentId: invoiceId,
          redirectUrl: paymentUrl,
        );
      }

      final errorMsg =
          responseData['ValidationErrors']?[0]?['Error'] ??
          responseData['Message'] ??
          'Unknown error occurred';
      return PaymentResponse.error(errorMessage: errorMsg);
    } catch (e) {
      return PaymentResponse.error(
        errorMessage: 'Payment error: ${e.toString()}',
      );
    }
  }

  @override
  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    try {
      final url = '$_baseUrl/v2/GetPaymentStatus';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'Key': paymentId,
          // Try both key types if needed; adjust based on MyFatoorah API behavior
          'KeyType':
              paymentId.length > 10
                  ? 'PaymentId'
                  : 'InvoiceId', // Heuristic based on ID length
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['IsSuccess'] == true) {
        final data = responseData['Data'];
        final invoiceStatus = data['InvoiceStatus'];

        return PaymentStatus(
          status: _mapInvoiceStatus(invoiceStatus),
          paymentId: paymentId,
          transactionId: data['InvoiceTransactions']?[0]?['TransactionId'],
          amount: double.tryParse(data['InvoiceValue'].toString()) ?? 0.0,
          currency: data['InvoiceDisplayValue'],
          timestamp: DateTime.tryParse(data['CreatedDate']),
          gatewayResponse: data,
        );
      }

      print(
        'MyFatoorahGateway: Status check failed - ${responseData['Message']}',
      );
      return PaymentStatus(
        status: PaymentStatusType.unknown,
        paymentId: paymentId,
        errorMessage: responseData['Message'] ?? 'Failed to check status',
      );
    } catch (e) {
      print('MyFatoorahGateway: Status check error - $e');
      return PaymentStatus(
        status: PaymentStatusType.unknown,
        paymentId: paymentId,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> processRefund(String paymentId, {double? amount}) async {
    // Refund implementation would need to be added separately
    // as it wasn't in the Python code provided
    return false;
  }

  @override
  bool validateCallback(Map<String, dynamic> data) {
    return data.containsKey('InvoiceId') && data.containsKey('InvoiceStatus');
  }

  @override
  PaymentStatus extractStatusFromCallback(Map<String, dynamic> data) {
    final invoiceId = data['InvoiceId']?.toString() ?? '';
    final invoiceStatus = data['InvoiceStatus']?.toString() ?? '';

    return PaymentStatus(
      status: _mapInvoiceStatus(invoiceStatus),
      paymentId: invoiceId,
      gatewayResponse: data,
    );
  }

  PaymentStatusType _mapInvoiceStatus(String invoiceStatus) {
    switch (invoiceStatus.toLowerCase()) {
      case 'paid':
        return PaymentStatusType.successful;
      case 'unpaid':
        return PaymentStatusType.pending;
      case 'failed':
      case 'expired':
        return PaymentStatusType.failed;
      default:
        return PaymentStatusType.unknown;
    }
  }
}
