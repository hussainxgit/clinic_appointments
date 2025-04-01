// lib/features/doctor/domain/entities/doctor.dart
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

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      bio: json['bio'],
      socialMedia:
          json['socialMedia'] != null
              ? Map<String, String>.from(json['socialMedia'])
              : null,
      createdAt: DateTime.parse(json['createdAt']),
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
