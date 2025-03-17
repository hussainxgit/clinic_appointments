// lib/features/payment/data/gateways/tap_gateway.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../domain/interfaces/payment_gateway.dart';

class TapGateway implements PaymentGateway {
  static const String _sandboxBaseUrl = 'https://api.tap.company/v2';
  static const String _productionBaseUrl = 'https://api.tap.company/v2';
  
  late final String _baseUrl;
  late final String _apiKey;
  late final bool _isTestMode;
  late final String? _secretKey; // For webhook validation
  
  @override
  String get gatewayId => 'tap';
  
  @override
  String get displayName => 'Tap Payments';
  
  @override
  String get iconAsset => 'assets/images/payment/tap_logo.png';
  
  @override
  Future<void> initialize(Map<String, dynamic> config) async {
    _apiKey = config['apiKey'] as String;
    _secretKey = config['secretKey'] as String?;
    _isTestMode = config['testMode'] as bool? ?? true;
    _baseUrl = _isTestMode ? _sandboxBaseUrl : _productionBaseUrl;
  }
  
  @override
  Future<PaymentResponse> createPayment(PaymentRequest request) async {
    try {
      final url = '$_baseUrl/charges';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'amount': request.amount,
          'currency': request.currency,
          'customer': {
            'first_name': request.customerName?.split(' ').first ?? 'Customer',
            'last_name': _extractLastName(request.customerName),
            'email': request.customerEmail,
            'phone': {
              'country_code': '965',
              'number': request.customerPhone?.replaceAll('+', '') ?? '',
            },
          },
          'source': {
            'id': 'src_card'
          },
          'redirect': {
            'url': request.returnUrl,
          },
          'post': {
            'url': request.callbackUrl,
          },
          'reference': {
            'transaction': request.referenceId,
            'order': request.referenceId,
          },
          'description': request.description ?? 'Payment',
          'metadata': request.metadata ?? {},
        }),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final chargeId = responseData['id'];
        final redirectUrl = responseData['transaction']?['url'];
        
        if (redirectUrl != null) {
          return PaymentResponse.redirect(
            paymentId: chargeId,
            redirectUrl: redirectUrl,
          );
        } else {
          return PaymentResponse.error(
            errorMessage: 'Redirect URL not found in response',
          );
        }
      } else {
        final errorMsg = responseData['message'] ?? responseData['errors']?[0]?['description'] ?? 'Unknown error occurred';
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
  
  String _extractLastName(String? fullName) {
    if (fullName == null || fullName.isEmpty) {
      return '';
    }
    
    final parts = fullName.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    
    return '';
  }
  
  @override
  Future<PaymentStatus> checkPaymentStatus(String paymentId) async {
    try {
      final url = '$_baseUrl/charges/$paymentId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final status = responseData['status'];
        
        PaymentStatusType paymentStatus;
        switch (status) {
          case 'CAPTURED':
            paymentStatus = PaymentStatusType.successful;
            break;
          case 'AUTHORIZED':
            paymentStatus = PaymentStatusType.processing;
            break;
          case 'INITIATED':
          case 'IN_PROGRESS':
            paymentStatus = PaymentStatusType.pending;
            break;
          case 'DECLINED':
          case 'RESTRICTED':
          case 'ABANDONED':
          case 'CANCELLED':
          case 'FAILED':
            paymentStatus = PaymentStatusType.failed;
            break;
          case 'REFUNDED':
            paymentStatus = PaymentStatusType.refunded;
            break;
          case 'PARTIALLY_REFUNDED':
            paymentStatus = PaymentStatusType.partiallyRefunded;
            break;
          default:
            paymentStatus = PaymentStatusType.unknown;
        }
        
        return PaymentStatus(
          status: paymentStatus,
          paymentId: paymentId,
          transactionId: responseData['reference']?['payment'],
          amount: double.tryParse(responseData['amount'].toString()) ?? 0.0,
          currency: responseData['currency'],
          timestamp: DateTime.tryParse(responseData['transaction']?['created'] ?? ''),
          gatewayResponse: responseData,
        );
      } else {
        return PaymentStatus(
          status: PaymentStatusType.unknown,
          paymentId: paymentId,
          errorMessage: responseData['message'] ?? 'Failed to check payment status',
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
      final url = '$_baseUrl/refunds';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'charge_id': paymentId,
          'amount': amount,
          'currency': 'KWD', // This should be dynamic based on the original payment
          'reason': 'requested_by_customer',
          'post': {
            'url': 'https://your-website.com/webhooks/refund',
          },
        }),
      );
      
      final responseData = jsonDecode(response.body);
      return response.statusCode == 200 && responseData['status'] == 'INITIATED';
    } catch (e) {
      print('Refund error: $e');
      return false;
    }
  }
  
  @override
  bool validateCallback(Map<String, dynamic> data) {
    if (_secretKey == null) {
      // Cannot validate without a secret key
      return true;
    }
    
    final providedHmac = data['hashString'];
    if (providedHmac == null) {
      return false;
    }
    
    // Prepare the data for HMAC calculation
    // This needs to be customized based on Tap's documentation
    final id = data['id'];
    final amount = data['amount'];
    final currency = data['currency'];
    final stringToHash = '$id$amount$currency';
    
    // Calculate HMAC
    final hmacBytes = Hmac(sha256, utf8.encode(_secretKey)).convert(utf8.encode(stringToHash));
    final calculatedHmac = hmacBytes.toString();
    
    return calculatedHmac == providedHmac;
  }
  
  @override
  PaymentStatus extractStatusFromCallback(Map<String, dynamic> data) {
    final id = data['id'] ?? '';
    final status = data['status'] ?? '';
    
    PaymentStatusType paymentStatus;
    switch (status) {
      case 'CAPTURED':
        paymentStatus = PaymentStatusType.successful;
        break;
      case 'AUTHORIZED':
        paymentStatus = PaymentStatusType.processing;
        break;
      case 'INITIATED':
      case 'IN_PROGRESS':
        paymentStatus = PaymentStatusType.pending;
        break;
      case 'DECLINED':
      case 'RESTRICTED':
      case 'ABANDONED':
      case 'CANCELLED':
      case 'FAILED':
        paymentStatus = PaymentStatusType.failed;
        break;
      case 'REFUNDED':
        paymentStatus = PaymentStatusType.refunded;
        break;
      case 'PARTIALLY_REFUNDED':
        paymentStatus = PaymentStatusType.partiallyRefunded;
        break;
      default:
        paymentStatus = PaymentStatusType.unknown;
    }
    
    return PaymentStatus(
      status: paymentStatus,
      paymentId: id,
      transactionId: data['reference']?['payment'],
      amount: double.tryParse(data['amount'].toString()) ?? 0.0,
      currency: data['currency'],
      gatewayResponse: data,
    );
  }
}