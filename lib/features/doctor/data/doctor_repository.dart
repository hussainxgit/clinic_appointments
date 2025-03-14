// lib/features/doctor/data/doctor_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/data/firebase_repository.dart';
import '../domain/entities/doctor.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getAll();
  Future<Doctor?> getById(String id);
  Future<Doctor> create(Doctor doctor);
  Future<Doctor> update(Doctor doctor);
  Future<bool> delete(String id);
  Future<List<Doctor>> getBySpecialty(String specialty);
  Future<List<Doctor>> getAvailableDoctors();
}

class DoctorRepositoryImpl extends FirebaseRepository<Doctor> implements DoctorRepository {
  DoctorRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : super(
          firestore: firestore,
          collection: 'doctors',
        );

  @override
  Doctor fromMap(Map<String, dynamic> map, String id) {
    return Doctor.fromJson({...map, 'id': id});
  }

  @override
  Map<String, dynamic> toMap(Doctor entity) {
    final map = entity.toJson();
    // Remove ID as Firestore handles this
    map.remove('id');
    return map;
  }

  @override
  String getId(Doctor entity) {
    return entity.id;
  }

  @override
  Future<List<Doctor>> getBySpecialty(String specialty) async {
    final snapshot = await firestore
        .collection(collection)
        .where('specialty', isEqualTo: specialty)
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<Doctor>> getAvailableDoctors() async {
    final snapshot = await firestore
        .collection(collection)
        .where('isAvailable', isEqualTo: true)
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }
}