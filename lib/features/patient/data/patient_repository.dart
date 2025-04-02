// lib/features/patient/data/patient_repository.dart
import '../../../core/data/firebase_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/patient.dart';

abstract class PatientRepository {
  Future<Result<List<Patient>>> getAll();
  Future<Result<Patient?>> getById(String id);
  Future<Result<Patient>> create(Patient patient);
  Future<Result<Patient>> update(Patient patient);
  Future<Result<bool>> delete(String id);
  Future<Result<Patient?>> findByPhone(String phone);
  Future<Result<List<Patient>>> searchByName(String name);
  Future<Result<List<Patient>>> getActivePatients();
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
  Future<Result<Patient?>> findByPhone(String phone) async {
    return ErrorHandler.guardAsync(() async {
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
    }, 'finding patient by phone');
  }

  @override
  Future<Result<List<Patient>>> searchByName(String name) async {
    return ErrorHandler.guardAsync(() async {
      if (name.isEmpty) return [];

      // Firebase doesn't support direct contains queries, so we'll use startAt/endAt
      final searchName = name.toLowerCase();

      final snapshot =
          await firestore
              .collection(collection)
              .orderBy('name')
              .startAt([searchName])
              .endAt(['$searchName\uf8ff'])
              .limit(20)
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'searching patients by name');
  }

  @override
  Future<Result<List<Patient>>> getActivePatients() async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await firestore
              .collection(collection)
              .where('status', isEqualTo: 'active')
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching active patients');
  }
}
