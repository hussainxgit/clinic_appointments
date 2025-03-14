// lib/features/appointment/data/appointment_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  AppointmentRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : super(
          firestore: firestore,
          collection: 'appointments',
        );

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
  Future<List<Appointment>> getByPatientId(String patientId) async {
    final snapshot = await firestore
        .collection(collection)
        .where('patientId', isEqualTo: patientId)
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<Appointment>> getByDoctorId(String doctorId) async {
    final snapshot = await firestore
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
    
    final snapshot = await firestore
        .collection(collection)
        .where('dateTime', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('dateTime', isLessThan: endDate.toIso8601String())
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<Appointment>> getByStatus(String status) async {
    final snapshot = await firestore
        .collection(collection)
        .where('status', isEqualTo: status)
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<Appointment> create(Appointment appointment) async {
    // Validate appointment
    _validateAppointment(appointment);
    
    return super.create(appointment);
  }

  @override
  Future<Appointment> update(Appointment appointment) async {
    // Validate appointment
    _validateAppointment(appointment);
    
    return super.update(appointment);
  }

  void _validateAppointment(Appointment appointment) {
    if (appointment.patientId.isEmpty) {
      throw InvalidAppointmentDataException('Patient ID cannot be empty');
    }
    if (appointment.doctorId.isEmpty) {
      throw InvalidAppointmentDataException('Doctor ID cannot be empty');
    }
    if (appointment.appointmentSlotId.isEmpty) {
      throw InvalidAppointmentDataException('Appointment slot ID cannot be empty');
    }
    if (appointment.status.isEmpty) {
      throw InvalidAppointmentDataException('Status cannot be empty');
    }
    if (appointment.paymentStatus.isEmpty) {
      throw InvalidAppointmentDataException('Payment status cannot be empty');
    }
    if (appointment.dateTime.isBefore(DateTime.now())) {
      throw AppointmentDateInPastException(appointment.dateTime);
    }
  }
}