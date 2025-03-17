// lib/features/payment/data/gateways/myfatoorah_gateway.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/interfaces/payment_gateway.dart';


class MyFatoorahGateway implements PaymentGateway {
  static const String _sandboxBaseUrl = 'https://apitest.myfatoorah.com';
  static const String _productionBaseUrl = 'https://api.myfatoorah.com';
  
  late final String _baseUrl;
  late final String _apiKey;
  late final bool _isTestMode;
  
  @override
  String get gatewayId => 'myfatoorah';
  
  @override
  String get displayName => 'MyFatoorah';
  
  @override
  String get iconAsset => 'assets/images/payment/myfatoorah_logo.png';
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _apiKey = config['apiKey'] as String;
    _isTestMode = config['testMode'] as bool? ?? true;
    _baseUrl = _isTestMode ? _sandboxBaseUrl : _productionBaseUrl;
  }
  
  @override
  Future<PaymentResponse> createPayment(PaymentRequest request) async {
    try {
      final url = '$_baseUrl/v2/InitiatePayment';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'InvoiceAmount': request.amount,
          'CurrencyIso': request.currency,
          'NotificationOption': 'LNK',
          'CustomerName': request.customerName,
          'CustomerEmail': request.customerEmail,
          'CustomerMobile': request.customerPhone,
          'CallBackUrl': request.callbackUrl,
          'ErrorUrl': request.callbackUrl,
          'Language': 'en',
          'CustomerReference': request.referenceId,
          'DisplayCurrencyIso': request.currency,
          'MobileCountryCode': '+965',
          'InvoiceItems': [
            {
              'ItemName': request.description ?? 'Payment',
              'Quantity': 1,
              'UnitPrice': request.amount,
            }
          ],
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['IsSuccess'] == true) {
        final sessionId = responseData['Data']['InvoiceId'].toString();
        
        // Get payment URL
        final paymentUrl = await _getPaymentUrl(sessionId);
        if (paymentUrl == null) {
          return PaymentResponse.error(
            errorMessage: 'Failed to get payment URL',
          );
        }
        
        return PaymentResponse.redirect(
          paymentId: sessionId,
          redirectUrl: paymentUrl,
        );
      } else {
        final errorMsg = responseData['ValidationErrors']?[0]?['Error'] ?? 
                        responseData['Message'] ?? 
                        'Unknown error occurred';
        return PaymentResponse.error(
          errorMessage: errorMsg,
        );
      }
    } catch (e) {
      return PaymentResponse.error(
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }
  
  Future<String?> _getPaymentUrl(String invoiceId) async {
    try {
      final url = '$_baseUrl/v2/ExecutePayment';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'InvoiceId': invoiceId,
          'PaymentMethodId': 2, // Credit Card
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['IsSuccess'] == true) {
        return responseData['Data']['PaymentURL'];
      }
      return null;
    } catch (e) {
      print('Error getting payment URL: $e');
      return null;
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
          'KeyType': 'InvoiceId',
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['IsSuccess'] == true) {
        final data = responseData['Data'];
        final invoiceStatus = data['InvoiceStatus'];
        
        PaymentStatusType status;
        switch (invoiceStatus) {
          case 'Paid':
            status = PaymentStatusType.successful;
            break;
          case 'Unpaid':
            status = PaymentStatusType.pending;
            break;
          case 'Failed':
            status = PaymentStatusType.failed;
            break;
          case 'Expired':
            status = PaymentStatusType.failed;
            break;
          default:
            status = PaymentStatusType.unknown;
        }
        
        return PaymentStatus(
          status: status,
          paymentId: paymentId,
          transactionId: data['InvoiceTransactions']?[0]?['TransactionId'],
          amount: double.tryParse(data['InvoiceValue'].toString()) ?? 0.0,
          currency: data['InvoiceDisplayValue'],
          timestamp: DateTime.tryParse(data['CreatedDate']),
          gatewayResponse: data,
        );
      } else {
        return PaymentStatus(
          status: PaymentStatusType.unknown,
          paymentId: paymentId,
          errorMessage: responseData['Message'] ?? 'Failed to check payment status',
          gatewayResponse: responseData,
        );
      }
    } catch (e) {
      return PaymentStatus(
        status: PaymentStatusType.unknown,
        paymentId: paymentId,
        errorMessage: 'Network error: ${e.toString()}',
      );
    }
  }
  
  @override
  Future<bool> processRefund(String paymentId, {double? amount}) async {
    try {
      // First get the payment details
      final paymentStatus = await checkPaymentStatus(paymentId);
      if (!paymentStatus.isSuccessful) {
        return false;
      }
      
      final transactionId = paymentStatus.transactionId;
      if (transactionId == null) {
        return false;
      }
      
      final url = '$_baseUrl/v2/MakeRefund';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'Key': transactionId,
          'KeyType': 'TransactionId',
          'RefundAmount': amount ?? paymentStatus.amount,
          'Comment': 'Refund requested',
        }),
      );
      
      final responseData = jsonDecode(response.body);
      return response.statusCode == 200 && responseData['IsSuccess'] == true;
    } catch (e) {
      print('Refund error: $e');
      return false;
    }
  }
  
  @override
  bool validateCallback(Map<String, dynamic> data) {
    // MyFatoorah doesn't provide webhook signature validation
    // But we can check for required fields
    return data.containsKey('InvoiceId') && data.containsKey('InvoiceStatus');
  }
  
  @override
  PaymentStatus extractStatusFromCallback(Map<String, dynamic> data) {
    final invoiceId = data['InvoiceId']?.toString() ?? '';
    final invoiceStatus = data['InvoiceStatus']?.toString() ?? '';
    
    PaymentStatusType status;
    switch (invoiceStatus) {
      case 'Paid':
        status = PaymentStatusType.successful;
        break;
      case 'Unpaid':
        status = PaymentStatusType.pending;
        break;
      case 'Failed':
        status = PaymentStatusType.failed;
        break;
      default:
        status = PaymentStatusType.unknown;
    }
    
    return PaymentStatus(
      status: status,
      paymentId: invoiceId,
      gatewayResponse: data,
    );
  }
}