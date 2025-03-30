import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, successful, failed, refunded, cancelled }

extension PaymentStatusExtension on PaymentStatus {
  String toStorageString() {
    return toString().split('.').last;
  }

  static PaymentStatus fromString(String status) {
    return PaymentStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => PaymentStatus.pending,
    );
  }
}

class PaymentRecord {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String paymentMethod;
  final String? invoiceId;
  final String? transactionId;
  final String? paymentLink;
  final bool linkSent;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? lastUpdated;
  final Map<String, dynamic>? metadata;
  PaymentRecord({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.invoiceId,
    this.transactionId,
    this.paymentLink,
    this.linkSent = false,
    required this.createdAt,
    this.completedAt,
    this.lastUpdated,
    this.metadata,
  });

  PaymentRecord copyWith({
    String? id,
    String? appointmentId,
    String? patientId,
    String? doctorId,
    double? amount,
    String? currency,
    PaymentStatus? status,
    String? paymentMethod,
    String? invoiceId,
    String? transactionId,
    String? paymentLink,
    bool? linkSent,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? lastUpdated,
    Map<String, dynamic>? metadata,
    String? paymentId,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      invoiceId: invoiceId ?? this.invoiceId,
      transactionId: transactionId ?? this.transactionId,
      paymentLink: paymentLink ?? this.paymentLink,
      linkSent: linkSent ?? this.linkSent,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'amount': amount,
      'currency': currency,
      'status': status.toStorageString(),
      'paymentMethod': paymentMethod,
      'invoiceId': invoiceId,
      'transactionId': transactionId,
      'paymentLink': paymentLink,
      'linkSent': linkSent,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PaymentRecord.fromMap(Map<String, dynamic> map, String docId) {
    return PaymentRecord(
      id: docId,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      amount:
          (map['amount'] is int)
              ? (map['amount'] as int).toDouble()
              : (map['amount'] as double? ?? 0.0),
      currency: map['currency'] ?? 'KWD',
      status: PaymentStatusExtension.fromString(map['status'] ?? 'pending'),
      paymentMethod: map['paymentMethod'] ?? 'online',
      invoiceId: map['invoiceId'],
      transactionId: map['transactionId'],
      paymentLink: map['paymentLink'],
      linkSent: map['linkSent'] ?? false,
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'])
              : DateTime.now(),
      completedAt:
          map['completedAt'] != null
              ? DateTime.parse(map['completedAt'])
              : null,
      lastUpdated:
          map['lastUpdated'] != null
              ? DateTime.parse(map['lastUpdated'])
              : null,
      metadata: map['metadata'],
    );
  }

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle Timestamp objects from Firestore
    final createdAt =
        data['createdAt'] is Timestamp
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.parse(data['createdAt']);

    final completedAt =
        data['completedAt'] == null
            ? null
            : data['completedAt'] is Timestamp
            ? (data['completedAt'] as Timestamp).toDate()
            : DateTime.parse(data['completedAt']);

    final lastUpdated =
        data['lastUpdated'] == null
            ? null
            : data['lastUpdated'] is Timestamp
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.parse(data['lastUpdated']);

    return PaymentRecord(
      id: doc.id,
      appointmentId: data['appointmentId'] ?? '',
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      amount:
          (data['amount'] is int)
              ? (data['amount'] as int).toDouble()
              : (data['amount'] as double? ?? 0.0),
      currency: data['currency'] ?? 'KWD',
      status: PaymentStatusExtension.fromString(data['status'] ?? 'pending'),
      paymentMethod: data['paymentMethod'] ?? 'online',
      invoiceId: data['invoiceId'],
      transactionId: data['transactionId'],
      paymentLink: data['paymentLink'],
      linkSent: data['linkSent'] ?? false,
      createdAt: createdAt,
      completedAt: completedAt,
      lastUpdated: lastUpdated,
      metadata: data['metadata'],
    );
  }
}
