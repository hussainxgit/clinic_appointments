// lib/features/doctor/data/mock_doctor_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/doctor.dart';

List<Doctor> getMockDoctors() {
  return [
    Doctor(
      id: 'D1',
      name: 'Dr. Ahmed Ali',
      specialty: 'General Practitioner',
      phoneNumber: '+96512345678',
      email: 'ahmed@example.com',
      imageUrl: 'https://www.nvisioncenters.com/wp-content/uploads/types-of-eye-care-professionals.jpg',
      isAvailable: true,
      bio: 'Dr. Ahmed Ali is a dedicated General Practitioner with over 15 years of experience.',
    ),
    Doctor(
      id: 'D2',
      name: 'Dr. Fatima Al-Sabah',
      specialty: 'Pediatrician',
      phoneNumber: '+96587654321',
      email: 'fatima.alsabah@example.com',
      imageUrl: 'https://mytpmg.com/wp-content/uploads/2021/02/eyedoctor-360-x-240.jpg',
      isAvailable: true,
    ),
    Doctor(
      id: 'D3',
      name: 'Dr. Khalid Al-Mutairi',
      specialty: 'Cardiologist',
      phoneNumber: '+96523456789',
      email: 'khalid.almutairi@example.com',
      isAvailable: false,
    ),
    Doctor(
      id: 'D4',
      name: 'Dr. Sarah Johnson',
      specialty: 'Ophthalmologist',
      phoneNumber: '+96512398765',
      email: 'sarah.johnson@example.com',
      isAvailable: true,
      bio: 'Dr. Sarah Johnson is a board-certified ophthalmologist specializing in retinal diseases.',
    ),
  ];
}

// Utility method to seed Firebase with mock data
Future<void> seedDoctorsCollection(FirebaseFirestore firestore) async {
  final batch = firestore.batch();
  final collection = firestore.collection('doctors');
  
  // Clear existing data
  final existingDocs = await collection.get();
  for (final doc in existingDocs.docs) {
    batch.delete(doc.reference);
  }
  
  // Add mock doctors
  final doctors = getMockDoctors();
  for (final doctor in doctors) {
    final docRef = collection.doc(doctor.id);
    final data = doctor.toJson();
    data.remove('id'); // Firestore uses document ID
    batch.set(docRef, data);
  }
  
  await batch.commit();
}