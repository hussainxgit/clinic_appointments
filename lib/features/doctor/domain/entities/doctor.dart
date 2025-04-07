// lib/features/doctor/domain/entities/doctor.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String phoneNumber;
  final String? email;
  final String? imageUrl;
  final String? bio;
  final bool isAvailable;
  final Map<String, String>? socialMedia;
  final DateTime? createdAt;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phoneNumber,
    this.email,
    this.imageUrl,
    this.bio,
    this.isAvailable = true,
    this.socialMedia,
    this.createdAt,
  });

  Doctor copyWith({
    String? id,
    String? name,
    String? specialty,
    String? phoneNumber,
    String? email,
    String? imageUrl,
    String? bio,
    bool? isAvailable,
    Map<String, String>? socialMedia,
    DateTime? createdAt,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      isAvailable: isAvailable ?? this.isAvailable,
      socialMedia: socialMedia ?? this.socialMedia,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // In your doctor repository implementation or doctor entity mapping
  factory Doctor.fromMap(Map<String, dynamic> map) {
    return Doctor(
      id: map['id'],
      name: map['name'] ?? '', // Add null check
      specialty: map['specialty'] ?? '', // Add null check
      phoneNumber: map['phoneNumber'] ?? '', // Add null check
      email: map['email'], // Already nullable in model
      imageUrl: map['imageUrl'], // Already nullable in model
      isAvailable: map['isAvailable'] ?? true, // Default to true if null
      bio: map['bio'],
      socialMedia:
          map['socialMedia'] != null
              ? Map<String, String>.from(map['socialMedia'])
              : null,
      // Be careful with dates - they often cause issues
      createdAt:
          map['createdAt'] != null
              ? (map['createdAt'] is Timestamp
                  ? (map['createdAt'] as Timestamp).toDate()
                  : DateTime.parse(map['createdAt']))
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'phoneNumber': phoneNumber,
      'email': email,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'bio': bio,
      'socialMedia': socialMedia,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
