import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/events/app_event.dart';
import '../../../core/di/core_providers.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/events/event_bus.dart';
import '../../doctor/data/doctor_provider.dart';
import '../data/appointment_slot_providers.dart';
import '../data/appointment_slot_repository.dart';
import '../domain/entities/appointment_slot.dart';
import '../../doctor/data/doctor_repository.dart';
import '../domain/entities/time_slot.dart';

part 'slot_generation_service.g.dart';

@riverpod
SlotGenerationService slotGenerationService(Ref ref) {
  return SlotGenerationService(
    slotRepository: ref.watch(appointmentSlotRepositoryProvider),
    doctorRepository: ref.watch(doctorRepositoryProvider),
    eventBus: ref.watch(eventBusProvider),
  );
}

class SlotGenerationService {
  final AppointmentSlotRepository _slotRepository;
  final DoctorRepository _doctorRepository;
  final EventBus _eventBus;

  SlotGenerationService({
    required AppointmentSlotRepository slotRepository,
    required DoctorRepository doctorRepository,
    required EventBus eventBus,
  }) : _slotRepository = slotRepository,
       _doctorRepository = doctorRepository,
       _eventBus = eventBus;

  /// Generates appointment slots based on the provided configuration
  Future<Result<List<AppointmentSlot>>> generateSlots(
    SlotGenerationConfig config,
  ) async {
    return ErrorHandler.guardAsync(() async {
      config.validate();
      await _validateDoctor(config.doctorId);

      final slots = await _generateSlotsForDateRange(config);
      final savedSlots = await _saveGeneratedSlots(slots);

      _eventBus.publish(SlotsGeneratedEvent(savedSlots));
      return savedSlots;
    }, 'generating appointment slots');
  }

  /// Validates that the doctor exists and is active
  Future<void> _validateDoctor(String doctorId) async {
    final doctorResult = await _doctorRepository.getById(doctorId);
    if (doctorResult.isFailure) {
      throw doctorResult.error;
    }
    if (doctorResult.data == null) {
      throw 'Doctor not found';
    }
  }

  /// Generates slots for the entire date range
  Future<List<AppointmentSlot>> _generateSlotsForDateRange(
    SlotGenerationConfig config,
  ) async {
    List<AppointmentSlot> allSlots = [];
    DateTime currentDate = config.startDate;

    while (!currentDate.isAfter(config.endDate)) {
      if (_isWorkingDay(currentDate, config)) {
        final daySlots = await _generateDaySlots(
          config: config,
          date: currentDate,
        );
        if (daySlots.isSuccess && daySlots.data.isNotEmpty) {
          allSlots.add(daySlots.data[0]);
        }
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return allSlots;
  }

  /// Generates slots for a specific day
  Future<Result<List<AppointmentSlot>>> _generateDaySlots({
    required SlotGenerationConfig config,
    required DateTime date,
  }) async {
    return ErrorHandler.guardAsync(() async {
      final weekDay = WeekDay.values[date.weekday - 1];
      final customHours = config.customHours?[weekDay];

      List<TimeSlot> dayTimeSlots = [];

      if (customHours != null && customHours.isNotEmpty) {
        // Generate time slots for custom hours
        for (final timeRange in customHours) {
          final rangeTimeSlots = _generateTimeSlots(
            config: config,
            date: date,
            startTime: timeRange.start,
            endTime: timeRange.end,
          );
          dayTimeSlots.addAll(rangeTimeSlots);
        }
      } else {
        // Generate time slots for standard hours
        final standardTimeSlots = _generateTimeSlots(
          config: config,
          date: date,
          startTime: config.workDayStart,
          endTime: config.workDayEnd,
        );
        dayTimeSlots.addAll(standardTimeSlots);
      }

      // Create a single AppointmentSlot for the entire day containing all time slots
      if (dayTimeSlots.isNotEmpty) {
        final appointmentSlot = AppointmentSlot(
          id: '',
          doctorId: config.doctorId,
          date: DateTime(date.year, date.month, date.day),
          timeSlots: dayTimeSlots,
          isActive: true,
        );

        return [appointmentSlot];
      }

      return [];
    }, 'generating day slots');
  }

  /// Generates time slots for a specific time range
  List<TimeSlot> _generateTimeSlots({
    required SlotGenerationConfig config,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    List<TimeSlot> timeSlots = [];
    DateTime currentStart = _createDateTime(date, startTime);
    final rangeEnd = _createDateTime(date, endTime);

    while (_canCreateSlot(currentStart, rangeEnd, config.slotDuration)) {
      timeSlots.add(
        TimeSlot(
          id:
              '${date.toIso8601String()}_${currentStart.hour}_${currentStart.minute}',
          startTime: TimeOfDay(
            hour: currentStart.hour,
            minute: currentStart.minute,
          ),
          duration: config.slotDuration,
          maxPatients: config.maxPatientsPerSlot,
          bookedPatients: 0,
          isActive: true,
        ),
      );
      currentStart = currentStart.add(config.slotDuration);
    }

    return timeSlots;
  }

  /// Saves generated slots after validation
  Future<List<AppointmentSlot>> _saveGeneratedSlots(
    List<AppointmentSlot> slots,
  ) async {
    List<AppointmentSlot> savedSlots = [];

    for (final slot in slots) {
      if (await _canSaveSlot(slot)) {
        final result = await _slotRepository.create(slot);
        if (result.isSuccess) {
          savedSlots.add(result.data);
        }
      }
    }

    if (savedSlots.isEmpty && slots.isNotEmpty) {
      throw 'No slots were saved. All slots already exist or failed to save.';
    }

    return savedSlots;
  }

  /// Checks if a slot can be saved
  Future<bool> _canSaveSlot(AppointmentSlot slot) async {
    final existingSlots = await _slotRepository.getByDoctorAndDate(
      slot.doctorId,
      slot.date,
    );

    if (existingSlots.isFailure) {
      return false;
    }

    // Check if there is already a slot for this doctor on this day
    if (existingSlots.data.isNotEmpty) {
      return false;
    }

    return true;
  }

  /// Checks if the given date is a working day
  bool _isWorkingDay(DateTime date, SlotGenerationConfig config) {
    final weekDay = WeekDay.values[date.weekday - 1];
    if (!config.workingDays.contains(weekDay)) return false;

    return config.excludeDates?.any(
          (excludeDate) =>
              date.year == excludeDate.year &&
              date.month == excludeDate.month &&
              date.day == excludeDate.day,
        ) !=
        true;
  }

  /// Creates a DateTime from a date and TimeOfDay
  DateTime _createDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Checks if a new slot can be created within the time range
  bool _canCreateSlot(DateTime current, DateTime end, Duration duration) {
    return current.add(duration).isBefore(end) ||
        current.add(duration).isAtSameMomentAs(end);
  }
}

/// Represents a time range with start and end times
class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const TimeRange({required this.start, required this.end});
}

/// Represents days of the week
enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

/// Event fired when slots are generated
class SlotsGeneratedEvent implements AppEvent {
  final List<AppointmentSlot> slots;

  const SlotsGeneratedEvent(this.slots);

  @override
  String get eventType => 'SlotsGeneratedEvent';
}

/// Configuration for slot generation
class SlotGenerationConfig {
  final String doctorId;
  final DateTime startDate;
  final DateTime endDate;
  final Duration slotDuration;
  final List<WeekDay> workingDays;
  final TimeOfDay workDayStart;
  final TimeOfDay workDayEnd;
  final List<DateTime>? excludeDates;
  final Map<WeekDay, List<TimeRange>>? customHours;
  final int maxPatientsPerSlot;

  const SlotGenerationConfig({
    required this.doctorId,
    required this.startDate,
    required this.endDate,
    required this.slotDuration,
    required this.workingDays,
    required this.workDayStart,
    required this.workDayEnd,
    this.excludeDates,
    this.customHours,
    this.maxPatientsPerSlot = 1,
  });

  void validate() {
    if (startDate.isAfter(endDate)) {
      throw 'Start date must be before end date';
    }
    if (startDate.isBefore(DateTime.now())) {
      throw 'Start date cannot be in the past';
    }
    if (workingDays.isEmpty) {
      throw 'At least one working day must be specified';
    }
    if (slotDuration.inMinutes < 15) {
      throw 'Slot duration must be at least 15 minutes';
    }
    if (maxPatientsPerSlot < 1) {
      throw 'Max patients per slot must be at least 1';
    }
  }
}
