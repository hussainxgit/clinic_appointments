// lib/features/appointment_slot/presentation/providers/appointment_slot_notifier.dart
import 'package:clinic_appointments/features/doctor/presentation/provider/doctor_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/result.dart';
import '../../data/appointment_slot_providers.dart';
import '../../domain/entities/appointment_slot.dart';
import '../../domain/exceptions/slot_exception.dart';

part 'appointment_slot_notifier.g.dart';

class AppointmentSlotState {
  final List<AppointmentSlot> slots;
  final bool isLoading;
  final String? error;

  AppointmentSlotState({
    required this.slots,
    this.isLoading = false,
    this.error,
  });

  AppointmentSlotState copyWith({
    List<AppointmentSlot>? slots,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentSlotState(
      slots: slots ?? this.slots,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

@riverpod
class AppointmentSlotNotifier extends _$AppointmentSlotNotifier {
  @override
  AppointmentSlotState build() {
    // Return an initial state without loading
    state = AppointmentSlotState(slots: [], isLoading: false);
    loadSlots();
    return state;
  }

  Future<void> loadSlots() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(appointmentSlotRepositoryProvider);
      final slots = await repository.getAll();
      state = state.copyWith(slots: slots, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshSlots() async {
    await loadSlots();
  }

  List<AppointmentSlot> getSlots({String? doctorId, DateTime? date}) {
    return state.slots.where((slot) {
      final doctorMatch = doctorId == null || slot.doctorId == doctorId;
      final dateMatch = date == null || _isSameDate(slot.date, date);
      return doctorMatch && dateMatch;
    }).toList();
  }

  Future<Result<AppointmentSlot>> addSlot(AppointmentSlot slot) async {
    try {
      // Validate slot data
      _validateSlot(slot);

      final repository = ref.read(appointmentSlotRepositoryProvider);

      // Check for duplicate ID
      if (state.slots.any((s) => s.id == slot.id)) {
        throw DuplicateSlotIdException(slot.id);
      }

      // Check for same day slot
      if (state.slots.any(
        (s) => s.doctorId == slot.doctorId && _isSameDate(s.date, slot.date),
      )) {
        throw SameDaySlotException(slot.doctorId, slot.date);
      }

      // Check if doctor exists
      final doctorNotifier = ref.read(doctorNotifierProvider);
      final doctor = doctorNotifier.doctors.firstWhere(
        (d) => d.id == slot.doctorId,
        orElse:
            () =>
                throw InvalidSlotDataException(
                  'Doctor with ID ${slot.doctorId} not found',
                ),
      );

      if (!doctor.isAvailable) {
        throw InvalidSlotDataException('Doctor is not available');
      }

      final savedSlot = await repository.create(slot);

      // Add the new slot to local state
      state = state.copyWith(slots: [...state.slots, savedSlot]);

      return Result.success(savedSlot);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<AppointmentSlot>> updateSlot(
    String slotId,
    AppointmentSlot Function(AppointmentSlot) update,
  ) async {
    try {
      final repository = ref.read(appointmentSlotRepositoryProvider);

      final index = state.slots.indexWhere((s) => s.id == slotId);
      if (index == -1) {
        throw SlotNotFoundException(slotId);
      }

      // Apply update
      final updatedSlot = update(state.slots[index]);

      // Validate updated slot
      _validateSlot(updatedSlot);

      // Save to repository
      final savedSlot = await repository.update(updatedSlot);

      // Update local state
      final updatedSlots = [...state.slots];
      updatedSlots[index] = savedSlot;
      state = state.copyWith(slots: updatedSlots);

      return Result.success(savedSlot);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<AppointmentSlot>> bookSlot(
    String slotId,
    String appointmentId,
  ) async {
    return updateSlot(slotId, (slot) {
      if (slot.isFullyBooked) {
        throw SlotFullyBookedException(slotId);
      }
      if (slot.date.isBefore(DateTime.now())) {
        throw SlotDateInPastException(slot.date);
      }

      return slot.bookAppointment(appointmentId);
    });
  }

  Future<Result<AppointmentSlot>> cancelSlot(
    String slotId,
    String appointmentId,
  ) async {
    return updateSlot(slotId, (slot) {
      if (slot.bookedPatients <= 0) {
        throw SlotNotBookedException(slotId);
      }
      if (!slot.appointmentIds.contains(appointmentId)) {
        throw Exception('Appointment $appointmentId not found in slot $slotId');
      }

      return slot.cancelAppointment(appointmentId);
    });
  }

  Future<Result<bool>> removeSlot(String slotId) async {
    try {
      final repository = ref.read(appointmentSlotRepositoryProvider);

      final index = state.slots.indexWhere((s) => s.id == slotId);
      if (index == -1) {
        throw SlotNotFoundException(slotId);
      }

      final slot = state.slots[index];
      if (slot.bookedPatients > 0) {
        throw SlotHasBookingsException(slotId);
      }

      if (slot.date.isBefore(DateTime.now())) {
        throw SlotDateInPastException(slot.date);
      }

      final result = await repository.delete(slotId);

      if (result) {
        // Update local state by removing the slot
        final updatedSlots = [...state.slots];
        updatedSlots.removeAt(index);
        state = state.copyWith(slots: updatedSlots);
      }

      return Result.success(result);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> removeSlotsByDoctorId(String doctorId) async {
    try {
      final repository = ref.read(appointmentSlotRepositoryProvider);

      final now = DateTime.now();
      final slotsToRemove =
          state.slots
              .where(
                (slot) =>
                    slot.doctorId == doctorId &&
                    !slot.date.isBefore(now) &&
                    slot.bookedPatients == 0,
              )
              .toList();

      if (slotsToRemove.isEmpty) {
        return Result.success(true);
      }

      bool allSuccessful = true;
      final idsToRemove = <String>[];

      for (final slot in slotsToRemove) {
        try {
          await repository.delete(slot.id);
          idsToRemove.add(slot.id);
        } catch (e) {
          allSuccessful = false;
          print('Failed to delete slot ${slot.id}: $e');
        }
      }

      // Update local state in one go by filtering out deleted slots
      if (idsToRemove.isNotEmpty) {
        final updatedSlots =
            state.slots
                .where((slot) => !idsToRemove.contains(slot.id))
                .toList();
        state = state.copyWith(slots: updatedSlots);
      }

      return Result.success(allSuccessful);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  bool isDoctorAvailable(String doctorId, DateTime date) {
    return getSlots(
      doctorId: doctorId,
      date: date,
    ).any((slot) => !slot.isFullyBooked);
  }

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

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
