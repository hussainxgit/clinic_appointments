// lib/features/appointment/data/appointment_repository.dart
import '../../../core/data/firebase_repository.dart';
import '../domain/entities/appointment.dart';
import '../domain/exceptions/appointment_exception.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAll();
  Future<Appointment?> getById(String id);
  Future<Appointment> create(Appointment appointment);
  Future<Appointment> update(Appointment appointment);
  Future<bool> delete(String id);
  Future<List<Appointment>> getByPatientId(String patientId);
  Future<List<Appointment>> getByDoctorId(String doctorId);
  Future<List<Appointment>> getByDate(DateTime date);
  Future<List<Appointment>> getByStatus(String status);
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
  Future<List<Appointment>> getAll() async {
    try {
      final snapshot = await firestore.collection(collection).get();
      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      throw Exception('Failed to get appointments: ${e.toString()}');
    }
  }

  @override
  String getId(Appointment entity) {
    return entity.id;
  }

  @override
  Future<List<Appointment>> getByPatientId(String patientId) async {
    final snapshot =
        await firestore
            .collection(collection)
            .where('patientId', isEqualTo: patientId)
            .get();

    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<Appointment>> getByDoctorId(String doctorId) async {
    final snapshot =
        await firestore
            .collection(collection)
            .where('doctorId', isEqualTo: doctorId)
            .get();

    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<Appointment>> getByDate(DateTime date) async {
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
  }

  @override
  Future<List<Appointment>> getByStatus(String status) async {
    final snapshot =
        await firestore
            .collection(collection)
            .where('status', isEqualTo: status)
            .get();

    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<Appointment> create(Appointment entity) async {
    try {
      // Validate appointment
      _validateAppointment(entity);

      // Create document
      final docRef = firestore.collection(collection).doc();
      final data = toMap(entity);
      await docRef.set(data);

      // Return appointment with generated ID
      return Appointment.fromMap({...data, 'id': docRef.id});
    } catch (e) {
      throw Exception('Failed to create appointment: ${e.toString()}');
    }
  }

  @override
  Future<Appointment> update(Appointment entity) async {
    try {
      // Validate appointment
      _validateAppointment(entity);

      // Update document
      await firestore
          .collection(collection)
          .doc(entity.id)
          .update(toMap(entity));

      return entity;
    } catch (e) {
      throw Exception('Failed to update appointment: ${e.toString()}');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await firestore.collection(collection).doc(id).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete appointment: ${e.toString()}');
    }
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
