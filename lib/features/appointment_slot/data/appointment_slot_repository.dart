// lib/features/appointment_slot/data/appointment_slot_repository.dart
import '../../../core/data/firebase_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/result.dart';
import '../domain/entities/appointment_slot.dart';
import '../domain/exceptions/slot_exception.dart';
import '../domain/exceptions/slot_exceptions.dart';

abstract class AppointmentSlotRepository {
  Future<Result<List<AppointmentSlot>>> getAll();
  Future<Result<AppointmentSlot?>> getById(String id);
  Future<Result<AppointmentSlot>> create(AppointmentSlot slot);
  Future<Result<AppointmentSlot>> update(AppointmentSlot slot);
  Future<Result<bool>> delete(String id);
  Future<Result<List<AppointmentSlot>>> getByDoctorId(String doctorId);
  Future<Result<List<AppointmentSlot>>> getByDate(DateTime date);
  Future<Result<List<AppointmentSlot>>> getByDoctorAndDate(
    String doctorId,
    DateTime date,
  );
  Future<Result<List<AppointmentSlot>>> getAvailableSlots(DateTime? fromDate);
}

class AppointmentSlotRepositoryImpl extends FirebaseRepository<AppointmentSlot>
    implements AppointmentSlotRepository {
  AppointmentSlotRepositoryImpl({required super.firestore})
    : super(collection: 'appointmentSlots');

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
  Future<Result<List<AppointmentSlot>>> getByDoctorId(String doctorId) async {
    return ErrorHandler.guardAsync(() async {
      final snapshot =
          await firestore
              .collection(collection)
              .where('doctorId', isEqualTo: doctorId)
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching slots by doctor ID');
  }

  @override
  Future<Result<List<AppointmentSlot>>> getByDate(DateTime date) async {
    return ErrorHandler.guardAsync(() async {
      // Format the date consistently for Firestore queries
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(days: 1));

      final snapshot =
          await firestore
              .collection(collection)
              .where(
                'date',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .where('date', isLessThan: endDate.toIso8601String())
              .get();

      return snapshot.docs.map((doc) => fromMap(doc.data(), doc.id)).toList();
    }, 'fetching slots by date');
  }

  @override
  Future<Result<List<AppointmentSlot>>> getByDoctorAndDate(
    String doctorId,
    DateTime date,
  ) async {
    return ErrorHandler.guardAsync(() async {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot =
          await firestore
              .collection(collection)
              .where('doctorId', isEqualTo: doctorId)
              .where('date', isGreaterThanOrEqualTo: startOfDay)
              .where('date', isLessThan: endOfDay)
              .get();

      return querySnapshot.docs
          .map((doc) => fromMap(doc.data(), doc.id))
          .toList();
    }, 'getting slots by doctor and date');
  }

  @override
  Future<Result<List<AppointmentSlot>>> getAvailableSlots(
    DateTime? fromDate,
  ) async {
    return ErrorHandler.guardAsync(() async {
      // If no date provided, use current date
      final startDate =
          fromDate != null
              ? DateTime(fromDate.year, fromDate.month, fromDate.day)
              : DateTime.now();

      final snapshot =
          await firestore
              .collection(collection)
              .where(
                'date',
                isGreaterThanOrEqualTo: startDate.toIso8601String(),
              )
              .get();

      final slots =
          snapshot.docs
              .map((doc) => fromMap(doc.data(), doc.id))
              .where((slot) => !slot.isFullyBooked)
              .toList();

      return slots;
    }, 'fetching available slots');
  }

  @override
  Future<Result<AppointmentSlot>> create(AppointmentSlot entity) async {
    return ErrorHandler.guardAsync(() async {
      // Validate slot before creating
      _validateSlot(entity);

      // Check for duplicates - use start of day for comparison
      final slotDate = DateTime(
        entity.date.year,
        entity.date.month,
        entity.date.day,
        entity.date.hour,
        entity.date.minute,
      );

      final existingSlotsResult = await getByDoctorAndDate(
        entity.doctorId,
        slotDate,
      );

      if (existingSlotsResult.isFailure) {
        throw existingSlotsResult.error;
      }

      // Check if there's any overlapping slot
      final existingSlots = existingSlotsResult.data;
      for (final existingSlot in existingSlots) {
        if (_slotsOverlap(existingSlot, entity)) {
          throw SlotOverlapException(entity.doctorId, entity.date);
        }
      }

      // Use the base implementation to create the slot
      final docRef = firestore.collection(collection).doc();
      await docRef.set(toMap(entity));
      return fromMap({...toMap(entity), 'id': docRef.id}, docRef.id);
    }, 'creating appointment slot');
  }

  @override
  Future<Result<AppointmentSlot>> update(AppointmentSlot entity) async {
    return ErrorHandler.guardAsync(() async {
      // Validate slot before updating
      _validateSlot(entity);

      // Use the base implementation to update the slot
      final id = getId(entity);
      await firestore.collection(collection).doc(id).update(toMap(entity));
      return entity;
    }, 'updating appointment slot');
  }

  @override
  Future<Result<bool>> delete(String id) async {
    return ErrorHandler.guardAsync(() async {
      // Get the slot first to validate
      final slotResult = await getById(id);

      if (slotResult.isFailure) {
        throw SlotNotFoundException(id);
      }

      final slot = slotResult.data;
      if (slot == null) {
        throw SlotNotFoundException(id);
      }

      if (slot.bookedPatients > 0) {
        throw SlotHasBookingsException(id);
      }

      if (slot.date.isBefore(DateTime.now())) {
        throw SlotDateInPastException(slot.date);
      }

      // Use the base implementation to delete the slot
      await firestore.collection(collection).doc(id).delete();
      return true;
    }, 'deleting appointment slot');
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
      throw InvalidSlotDataException(
        'Booked patients cannot exceed max patients',
      );
    }
  }

  bool _slotsOverlap(AppointmentSlot slot1, AppointmentSlot slot2) {
    // Consider slots of same duration for simplicity
    const duration = Duration(minutes: 30);

    final slot1End = slot1.date.add(duration);
    final slot2End = slot2.date.add(duration);

    return slot1.date.isBefore(slot2End) && slot2.date.isBefore(slot1End);
  }
}
