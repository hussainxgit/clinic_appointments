// lib/features/messaging/data/models/sms_record.dart
class SmsRecord {
  final String id;
  final String providerId;
  final String messageId;
  final String to;
  final String from;
  final String body;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  SmsRecord({
    required this.id,
    required this.providerId,
    this.messageId = '',
    required this.to,
    required this.from,
    required this.body,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.errorMessage,
    this.metadata,
  });

  SmsRecord copyWith({
    String? id,
    String? providerId,
    String? messageId,
    String? to,
    String? from,
    String? body,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return SmsRecord(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      messageId: messageId ?? this.messageId,
      to: to ?? this.to,
      from: from ?? this.from,
      body: body ?? this.body,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'messageId': messageId,
      'to': to,
      'from': from,
      'body': body,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  factory SmsRecord.fromMap(Map<String, dynamic> map, String id) {
    return SmsRecord(
      id: id,
      providerId: map['providerId'] ?? '',
      messageId: map['messageId'] ?? '',
      to: map['to'] ?? '',
      from: map['from'] ?? '',
      body: map['body'] ?? '',
      status: map['status'] ?? 'unknown',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      errorMessage: map['errorMessage'],
      metadata: map['metadata'],
    );
  }
}