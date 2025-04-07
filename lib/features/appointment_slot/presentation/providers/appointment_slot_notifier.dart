// lib/features/appointment_slot/presentation/providers/appointment_slot_notifier.dart
import 'package:clinic_appointments/features/doctor/presentation/provider/doctor_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/utils/result.dart';
import '../../../appointment/domain/exceptions/appointment_exception.dart';
import '../../data/appointment_slot_providers.dart';
import '../../domain/entities/appointment_slot.dart';
import '../../domain/exceptions/slot_exceptions.dart';
import '../../domain/exceptions/time_slot_exceptions.dart';

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
    state = AppointmentSlotState(slots: [], isLoading: false);
    loadSlots();
    return state;
  }

  Future<void> loadSlots() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repository = ref.read(appointmentSlotRepositoryProvider);
      final slots = await repository.getAll();
      state = state.copyWith(slots: slots.data, isLoading: false);
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
      return doctorMatch && dateMatch && slot.isActive;
    }).toList();
  }

Future<Result<AppointmentSlot>> addSlot(AppointmentSlot slot) async {
  try {
    _validateSlot(slot);

    final repository = ref.read(appointmentSlotRepositoryProvider);

    // Check for duplicate ID
    if (state.slots.any((s) => s.id == slot.id)) {
      throw DuplicateSlotIdException(slot.id);
    }

    // Check if doctor exists and is available
    final doctorNotifier = ref.read(doctorNotifierProvider);
    final doctor = doctorNotifier.doctors.firstWhere(
      (d) => d.id == slot.doctorId,
      orElse: () => throw InvalidSlotDataException(
        'Doctor with ID ${slot.doctorId} not found',
      ),
    );

    if (!doctor.isAvailable) {
      throw InvalidSlotDataException('Doctor is not available');
    }

    final savedSlot = await repository.create(slot);
    state = state.copyWith(slots: [...state.slots, savedSlot.data]);

    // Publish event
    ref.read(eventBusProvider).publish(SlotCreatedEvent(savedSlot.data));
    
    return Result.success(savedSlot.data);
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

      final updatedSlot = update(state.slots[index]);
      _validateSlot(updatedSlot);

      final savedSlot = await repository.update(updatedSlot);

      final updatedSlots = [...state.slots];
      updatedSlots[index] = savedSlot.data;
      state = state.copyWith(slots: updatedSlots);

      return Result.success(savedSlot.data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<AppointmentSlot>> bookTimeSlot(
    String slotId,
    String timeSlotId,
    String appointmentId,
  ) async {
    return updateSlot(slotId, (slot) {
      final timeSlotIndex = slot.timeSlots.indexWhere(
        (ts) => ts.id == timeSlotId,
      );
      if (timeSlotIndex == -1) {
        throw TimeSlotNotFoundException(timeSlotId);
      }

      final timeSlot = slot.timeSlots[timeSlotIndex];
      if (timeSlot.isFullyBooked) {
        throw TimeSlotFullyBookedException(timeSlotId);
      }

      if (slot.date.isBefore(DateTime.now())) {
        throw SlotDateInPastException(slot.date);
      }

      final updatedTimeSlots = [...slot.timeSlots];
      updatedTimeSlots[timeSlotIndex] = timeSlot.bookAppointment(appointmentId);

      return slot.copyWith(timeSlots: updatedTimeSlots);
    });
  }

  Future<Result<AppointmentSlot>> cancelTimeSlot(
    String slotId,
    String timeSlotId,
    String appointmentId,
  ) async {
    return updateSlot(slotId, (slot) {
      final timeSlotIndex = slot.timeSlots.indexWhere(
        (ts) => ts.id == timeSlotId,
      );
      if (timeSlotIndex == -1) {
        throw TimeSlotNotFoundException(timeSlotId);
      }

      final timeSlot = slot.timeSlots[timeSlotIndex];
      if (!timeSlot.appointmentIds.contains(appointmentId)) {
        throw AppointmentNotFoundException(appointmentId);
      }

      final updatedTimeSlots = [...slot.timeSlots];
      updatedTimeSlots[timeSlotIndex] = timeSlot.cancelAppointment(
        appointmentId,
      );

      return slot.copyWith(timeSlots: updatedTimeSlots);
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
      if (slot.hasBookedPatients) {
        throw SlotHasBookingsException(slotId);
      }

      if (slot.date.isBefore(DateTime.now())) {
        throw SlotDateInPastException(slot.date);
      }

      final result = await repository.delete(slotId);

      if (result.isSuccess) {
        final updatedSlots = [...state.slots];
        updatedSlots.removeAt(index);
        state = state.copyWith(slots: updatedSlots);
      }

      return Result.success(result.data);
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
                    !slot.hasBookedPatients,
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
    if (slot.timeSlots.isEmpty) {
      throw InvalidSlotDataException('Slot must have at least one time slot');
    }

    for (final timeSlot in slot.timeSlots) {
      if (timeSlot.maxPatients <= 0) {
        throw InvalidSlotDataException('Max patients must be greater than 0');
      }
      if (timeSlot.bookedPatients < 0) {
        throw InvalidSlotDataException('Booked patients cannot be negative');
      }
      if (timeSlot.bookedPatients > timeSlot.maxPatients) {
        throw InvalidSlotDataException(
          'Booked patients cannot exceed max patients',
        );
      }
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
