// lib/features/appointment/data/appointment_repository.dart
import '../../../core/data/firebase_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/appointment.dart';
import '../domain/exceptions/appointment_exception.dart';

abstract class AppointmentRepository {
  Future<Result<List<Appointment>>> getAll();
  Future<Result<Appointment?>> getById(String id);
  Future<Result<Appointment>> create(Appointment appointment);
  Future<Result<Appointment>> update(Appointment appointment);
  Future<Result<bool>> delete(String id);
  Future<Result<List<Appointment>>> getByPatientId(String patientId);
  Future<Result<List<Appointment>>> getByDoctorId(String doctorId);
  Future<Result<List<Appointment>>> getByDate(DateTime date);
  Future<Result<List<Appointment>>> getByStatus(String status);
}

class AppointmentRepositoryImpl extends FirebaseRepository<Appointment>
    implements AppointmentRepository {
  AppointmentRepositoryImpl({required super.firestore})
    : super(collection: 'appointments');

  @override
  Appointment fromMap(Map<String, dynamic> map, String id) {
    return Appointment.fromMap({...map, 'id': id});
  }

  @override
  Map<String, dynamic> toMap(Appointment entity) {
    final map = entity.toMap();
    map.remove('id'); // Firestore handles ID
    return map;
  }

  @override
  String getId(Appointment entity) {
    return entity.id;
  }

  @override
  Future<Result<List<Appointment>>> getByPatientId(String patientId) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await firestore
              .collection(collection)
              .where('patientId', isEqualTo: patientId)
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching appointments by patient ID');
  }

  @override
  Future<Result<List<Appointment>>> getByDoctorId(String doctorId) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await firestore
              .collection(collection)
              .where('doctorId', isEqualTo: doctorId)
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching appointments by doctor ID');
  }

  @override
  Future<Result<List<Appointment>>> getByDate(DateTime date) async {
    return ErrorHandler.guardAsync(() async {
      // Format the date consistently for Firestore queries
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      final snapshot =
          await firestore
              .collection(collection)
              .where(
                'dateTime',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .where('dateTime', isLessThan: endDate.toIso8601String())
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching appointments by date');
  }

  @override
  Future<Result<List<Appointment>>> getByStatus(String status) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await firestore
              .collection(collection)
              .where('status', isEqualTo: status)
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching appointments by status');
  }

  @override
  Future<Result<Appointment>> create(Appointment entity) async {
    return ErrorHandler.guardAsync(() async {
      // Validate appointment
      _validateAppointment(entity);

      // Create document
      final docRef = firestore.collection(collection).doc();
      final data = toMap(entity);
      await docRef.set(data);

      // Return appointment with generated ID
      return Appointment.fromMap({...data, 'id': docRef.id});
    }, 'creating appointment');
  }

  @override
  Future<Result<Appointment>> update(Appointment entity) async {
    return ErrorHandler.guardAsync(() async {
      // Validate appointment
      _validateAppointment(entity);

      // Update document
      await firestore
          .collection(collection)
          .doc(entity.id)
          .update(toMap(entity));

      return entity;
    }, 'updating appointment');
  }

  @override
  Future<Result<bool>> delete(String id) async {
    return ErrorHandler.guardAsync(() async {
      await firestore.collection(collection).doc(id).delete();
      return true;
    }, 'deleting appointment');
  }

  // Helper method to validate appointment data
  void _validateAppointment(Appointment appointment) {
    if (appointment.patientId.isEmpty) {
      throw InvalidAppointmentDataException('Patient ID cannot be empty');
    }
    if (appointment.doctorId.isEmpty) {
      throw InvalidAppointmentDataException('Doctor ID cannot be empty');
    }
    if (appointment.appointmentSlotId.isEmpty) {
      throw InvalidAppointmentDataException(
        'Appointment slot ID cannot be empty',
      );
    }
    // Don't validate past dates here as it might prevent historical data
  }
}
