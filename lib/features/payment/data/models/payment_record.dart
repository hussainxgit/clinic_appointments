// lib/features/payment/data/models/payment_record.dart
import 'package:clinic_appointments/features/payment/domain/interfaces/payment_gateway.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentRecord {
  final String id;
  final String referenceId; // Appointment or invoice ID
  final String gatewayId;
  final String gatewayPaymentId;
  final String patientId;
  final double amount;
  final String currency;
  final String status;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final String? errorMessage;

  PaymentRecord({
    required this.id,
    required this.referenceId,
    required this.gatewayId,
    required this.gatewayPaymentId,
    required this.patientId,
    required this.amount,
    required this.currency,
    required this.status,
    this.transactionId,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.errorMessage,
  });

  PaymentRecord copyWith({
    String? id,
    String? referenceId,
    String? gatewayId,
    String? gatewayPaymentId,
    String? patientId,
    double? amount,
    String? currency,
    String? status,
    String? transactionId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    String? errorMessage,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      gatewayId: gatewayId ?? this.gatewayId,
      gatewayPaymentId: gatewayPaymentId ?? this.gatewayPaymentId,
      patientId: patientId ?? this.patientId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'gatewayId': gatewayId,
      'gatewayPaymentId': gatewayPaymentId,
      'patientId': patientId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'transactionId': transactionId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
      'errorMessage': errorMessage,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map, String id) {
    return PaymentRecord(
      id: id,
      referenceId: map['referenceId'] ?? '',
      gatewayId: map['gatewayId'] ?? '',
      gatewayPaymentId: map['gatewayPaymentId'] ?? '',
      patientId: map['patientId'] ?? '',
      amount: (map['amount'] is int) 
          ? (map['amount'] as int).toDouble() 
          : (map['amount'] as double? ?? 0.0),
      currency: map['currency'] ?? '',
      status: map['status'] ?? '',
      transactionId: map['transactionId'],
      createdAt: map['createdAt'] is Timestamp 
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] == null
          ? null
          : map['updatedAt'] is Timestamp
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt']),
      metadata: map['metadata'],
      errorMessage: map['errorMessage'],
    );
  }

  factory PaymentRecord.fromPaymentStatus(
    PaymentStatus status, {
    required String id,
    required String referenceId,
    required String gatewayId,
    required String patientId,
    required double amount,
    required String currency,
    required DateTime createdAt,
  }) {
    String paymentStatus;
    switch (status.status) {
      case PaymentStatusType.successful:
        paymentStatus = 'successful';
        break;
      case PaymentStatusType.pending:
        paymentStatus = 'pending';
        break;
      case PaymentStatusType.processing:
        paymentStatus = 'processing';
        break;
      case PaymentStatusType.failed:
        paymentStatus = 'failed';
        break;
      case PaymentStatusType.refunded:
        paymentStatus = 'refunded';
        break;
      case PaymentStatusType.partiallyRefunded:
        paymentStatus = 'partially_refunded';
        break;
      default:
        paymentStatus = 'unknown';
    }

    return PaymentRecord(
      id: id,
      referenceId: referenceId,
      gatewayId: gatewayId,
      gatewayPaymentId: status.paymentId,
      patientId: patientId,
      amount: amount,
      currency: currency,
      status: paymentStatus,
      transactionId: status.transactionId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      metadata: status.gatewayResponse,
      errorMessage: status.errorMessage,
    );
  }
}