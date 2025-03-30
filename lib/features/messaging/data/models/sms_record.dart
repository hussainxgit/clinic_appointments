import 'package:cloud_firestore/cloud_firestore.dart';

class SmsRecord {
  final String id;
  final String recipient;
  final String message;
  final String sender;
  final String status;
  final DateTime createdAt;
  final String? messageId;
  final Map<String, dynamic>? metadata;

  SmsRecord({
    this.id = '',
    required this.recipient,
    required this.message,
    required this.sender,
    this.status = 'pending',
    DateTime? createdAt,
    this.messageId,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  SmsRecord copyWith({
    String? id,
    String? recipient,
    String? message,
    String? sender,
    String? status,
    DateTime? createdAt,
    String? messageId,
    Map<String, dynamic>? metadata,
  }) {
    return SmsRecord(
      id: id ?? this.id,
      recipient: recipient ?? this.recipient,
      message: message ?? this.message,
      sender: sender ?? this.sender,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      messageId: messageId ?? this.messageId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipient': recipient,
      'message': message,
      'sender': sender,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'messageId': messageId,
      'metadata': metadata,
    };
  }

  factory SmsRecord.fromMap(Map<String, dynamic> map, String documentId) {
    // Handle Timestamp objects from Firestore
    DateTime createdAt;
    if (map['createdAt'] is Timestamp) {
      createdAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      createdAt = DateTime.parse(map['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    return SmsRecord(
      id: documentId,
      recipient: map['recipient'] ?? '',
      message: map['message'] ?? '',
      sender: map['sender'] ?? '',
      status: map['status'] ?? 'unknown',
      createdAt: createdAt,
      messageId: map['messageId'],
      metadata: map['metadata'],
    );
  }
}
