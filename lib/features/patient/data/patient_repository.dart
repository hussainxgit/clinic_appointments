// lib/features/patient/data/patient_repository.dart
import '../../../core/data/firebase_repository.dart';
import '../domain/entities/patient.dart';

abstract class PatientRepository {
  Future<List<Patient>> getAll();
  Future<Patient?> getById(String id);
  Future<Patient> create(Patient patient);
  Future<Patient> update(Patient patient);
  Future<bool> delete(String id);
  Future<Patient?> findByPhone(String phone);
  Future<List<Patient>> searchByName(String name);
  Future<List<Patient>> getActivePatients();
}

class PatientRepositoryImpl extends FirebaseRepository<Patient>
    implements PatientRepository {
  PatientRepositoryImpl({required super.firestore})
    : super(collection: 'patients');

  @override
  Patient fromMap(Map<String, dynamic> map, String id) {
    // Fix: Ensure appointmentIds is properly cast to List<String>
    if (map.containsKey('appointmentIds') && map['appointmentIds'] != null) {
      // Convert List<dynamic> to List<String>
      map['appointmentIds'] =
          (map['appointmentIds'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
    }

    return Patient.fromMap({...map, 'id': id});
  }

  @override
  Map<String, dynamic> toMap(Patient entity) {
    final map = entity.toMap();
    map.remove('id'); // Firestore handles ID
    return map;
  }

  @override
  String getId(Patient entity) {
    return entity.id;
  }

  @override
  Future<Patient?> findByPhone(String phone) async {
    final snapshot =
        await firestore
            .collection(collection)
            .where('phone', isEqualTo: phone)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return fromMap(doc.data(), doc.id);
  }

  @override
  Future<List<Patient>> searchByName(String name) async {
    // Firebase doesn't support direct contains queries, so we'll do a simple startsWith
    final lowerName = name.toLowerCase();
    final upperName =
        lowerName.substring(0, lowerName.length - 1) +
        String.fromCharCode(lowerName.codeUnitAt(lowerName.length - 1) + 1);

    final snapshot =
        await firestore
            .collection(collection)
            .where('name', isGreaterThanOrEqualTo: lowerName)
            .where('name', isLessThan: upperName)
            .get();

    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<Patient>> getActivePatients() async {
    final snapshot =
        await firestore
            .collection(collection)
            .where('status', isEqualTo: 'active')
            .get();

    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }
}
