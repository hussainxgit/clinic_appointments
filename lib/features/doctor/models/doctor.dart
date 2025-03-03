class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String phoneNumber;
  String? email;
  String? imageUrl;
  String? bio;
  bool isAvailable = true;
  final Map<String, String>? socialMedia;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.phoneNumber,
    this.email,
    this.imageUrl,
    this.isAvailable = true,
    this.socialMedia,
    this.bio,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      specialty: json['specialty'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'],
      bio: json['bio'],
      //TODO: add socialMedia to fromJson
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
      'bio': isAvailable,
      //TODO: add socialMedia to toJson
    };
  }
}
