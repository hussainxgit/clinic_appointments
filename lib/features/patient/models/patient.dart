class Patient {
  final String id;
  String name;
  String phone;
  DateTime registeredAt;
  String? notes;
  
  Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.registeredAt,
    this.notes,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      registeredAt: DateTime.parse(json['registeredAt']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'registeredAt': registeredAt.toIso8601String(),
      'notes': notes,
    };
  }
}
