// lib/features/doctor/data/doctor_repository.dart
import '../../../core/data/firebase_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/doctor.dart';

abstract class DoctorRepository {
  Future<Result<List<Doctor>>> getAll();
  Future<Result<Doctor?>> getById(String id);
  Future<Result<Doctor>> create(Doctor doctor);
  Future<Result<Doctor>> update(Doctor doctor);
  Future<Result<bool>> delete(String id);
  Future<Result<List<Doctor>>> getBySpecialty(String specialty);
  Future<Result<List<Doctor>>> getAvailableDoctors();
}

class DoctorRepositoryImpl extends FirebaseRepository<Doctor>
    implements DoctorRepository {
  DoctorRepositoryImpl({required super.firestore})
    : super(collection: 'doctors');

  @override
  Doctor fromMap(Map<String, dynamic> map, String id) {
    return Doctor.fromMap({...map, 'id': id});
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
  Future<Result<List<Doctor>>> getBySpecialty(String specialty) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await firestore
              .collection(collection)
              .where('specialty', isEqualTo: specialty)
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching doctors by specialty');
  }

  @override
  Future<Result<List<Doctor>>> getAvailableDoctors() async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await firestore
              .collection(collection)
              .where('isAvailable', isEqualTo: true)
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching available doctors');
  }

  @override
  Future<Result<Doctor?>> getById(String id) async {
    return ErrorHandler.guardAsync(() async {
      final doc = await firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        return fromMap(doc.data()!, doc.id);
      } else {
        return null;
      }
    }, 'fetching doctor by ID');
  }
}
