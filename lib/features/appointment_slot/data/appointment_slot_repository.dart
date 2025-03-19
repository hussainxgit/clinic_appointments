// lib/features/appointment_slot/data/appointment_slot_repository.dart
import '../../../core/data/firebase_repository.dart';
import '../domain/entities/appointment_slot.dart';
import '../domain/exceptions/slot_exception.dart';

abstract class AppointmentSlotRepository {
  Future<List<AppointmentSlot>> getAll();
  Future<AppointmentSlot?> getById(String id);
  Future<AppointmentSlot> create(AppointmentSlot slot);
  Future<AppointmentSlot> update(AppointmentSlot slot);
  Future<bool> delete(String id);
  Future<List<AppointmentSlot>> getByDoctorId(String doctorId);
  Future<List<AppointmentSlot>> getByDate(DateTime date);
  Future<List<AppointmentSlot>> getByDoctorAndDate(String doctorId, DateTime date);
  Future<List<AppointmentSlot>> getAvailableSlots(DateTime? fromDate);
}

class AppointmentSlotRepositoryImpl extends FirebaseRepository<AppointmentSlot> 
    implements AppointmentSlotRepository {
  
  AppointmentSlotRepositoryImpl({
    required super.firestore,
  }) : super(
          collection: 'appointmentSlots',
        );

  @override
  AppointmentSlot fromMap(Map<String, dynamic> map, String id) {
    return AppointmentSlot.fromMap({...map, 'id': id});
  }

  @override
  Map<String, dynamic> toMap(AppointmentSlot entity) {
    final map = entity.toMap();
    map.remove('id'); // Firestore handles ID
    return map;
  }

  @override
  String getId(AppointmentSlot entity) {
    return entity.id;
  }

  @override
  Future<List<AppointmentSlot>> getByDoctorId(String doctorId) async {
    final snapshot = await firestore
        .collection(collection)
        .where('doctorId', isEqualTo: doctorId)
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<AppointmentSlot>> getByDate(DateTime date) async {
    // Format the date consistently for Firestore queries
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    
    final snapshot = await firestore
        .collection(collection)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThan: endDate.toIso8601String())
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<AppointmentSlot>> getByDoctorAndDate(String doctorId, DateTime date) async {
    // Format the date consistently for Firestore queries
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = startDate.add(const Duration(days: 1));
    
    final snapshot = await firestore
        .collection(collection)
        .where('doctorId', isEqualTo: doctorId)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('date', isLessThan: endDate.toIso8601String())
        .get();
    
    return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<AppointmentSlot>> getAvailableSlots(DateTime? fromDate) async {
    // If no date provided, use current date
    final startDate = fromDate != null 
        ? DateTime(fromDate.year, fromDate.month, fromDate.day)
        : DateTime.now();
    
    final snapshot = await firestore
        .collection(collection)
        .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .get();
    
    return snapshot.docs
        .map((doc) => fromMap(doc.data(), doc.id))
        .where((slot) => !slot.isFullyBooked)
        .toList();
  }

  @override
  Future<AppointmentSlot> create(AppointmentSlot slot) async {
    // Validate slot before creating
    _validateSlot(slot);
    
    // Check for duplicates
    final existingSlots = await getByDoctorAndDate(slot.doctorId, slot.date);
    if (existingSlots.isNotEmpty) {
      throw SameDaySlotException(slot.doctorId, slot.date);
    }
    
    return super.create(slot);
  }

  @override
  Future<AppointmentSlot> update(AppointmentSlot slot) async {
    // Validate slot before updating
    _validateSlot(slot);
    return super.update(slot);
  }

  @override
  Future<bool> delete(String id) async {
    final slot = await getById(id);
    if (slot == null) {
      throw SlotNotFoundException(id);
    }
    
    if (slot.bookedPatients > 0) {
      throw SlotHasBookingsException(id);
    }
    
    if (slot.date.isBefore(DateTime.now())) {
      throw SlotDateInPastException(slot.date);
    }
    
    return super.delete(id);
  }

  // Validate slot data
  void _validateSlot(AppointmentSlot slot) {
    if (slot.doctorId.isEmpty) {
      throw InvalidSlotDataException('Doctor ID cannot be empty');
    }
    if (slot.maxPatients <= 0) {
      throw InvalidSlotDataException('Max patients must be greater than 0');
    }
    if (slot.bookedPatients < 0) {
      throw InvalidSlotDataException('Booked patients cannot be negative');
    }
    if (slot.bookedPatients > slot.maxPatients) {
      throw InvalidSlotDataException('Booked patients cannot exceed max patients');
    }
  }
}