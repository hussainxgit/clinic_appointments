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

  /// Generates appointment slots for a doctor based on their schedule
  Future<Result<List<AppointmentSlot>>> generateSlots({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
    required Duration slotDuration,
    required List<WeekDay> workingDays,
    required TimeOfDay workDayStart,
    required TimeOfDay workDayEnd,
    List<DateTime>? excludeDates,
    Map<WeekDay, List<TimeRange>>? customHours,
  }) async {
    debugPrint('📅 SlotGenerationService.generateSlots started');
    return ErrorHandler.guardAsync(() async {
      // Validate doctor
      debugPrint('🔍 Validating doctor: $doctorId');
      final doctorResult = await _doctorRepository.getById(doctorId);
      if (doctorResult.isFailure) {
        debugPrint('❌ Doctor validation failed: ${doctorResult.error}');
        throw doctorResult.error;
      }
      if (doctorResult.data == null) {
        debugPrint('❌ Doctor not found: $doctorId');
        throw 'Doctor not found';
      }
      debugPrint('✅ Doctor validated successfully');

      // Validate dates
      if (startDate.isAfter(endDate)) {
        throw 'Start date must be before end date';
      }
      if (startDate.isBefore(DateTime.now())) {
        throw 'Start date cannot be in the past';
      }

      // Generate slots
      List<AppointmentSlot> generatedSlots = [];
      DateTime currentDate = startDate;
      debugPrint('🔄 Starting slot generation loop');

      while (!currentDate.isAfter(endDate)) {
        if (_shouldGenerateForDay(currentDate, workingDays, excludeDates)) {
          debugPrint('📆 Generating slots for date: $currentDate');
          final daySlots = await _generateDaySlots(
            doctorId: doctorId,
            date: currentDate,
            slotDuration: slotDuration,
            workDayStart: workDayStart,
            workDayEnd: workDayEnd,
            customHours: customHours?[WeekDay.values[currentDate.weekday - 1]],
          );

          if (daySlots.isFailure) {
            debugPrint(
              '❌ Failed generating slots for date $currentDate: ${daySlots.error}',
            );
            throw daySlots.error;
          }

          debugPrint(
            '✅ Generated ${daySlots.data.length} slots for date $currentDate',
          );
          generatedSlots.addAll(daySlots.data);
        } else {
          debugPrint(
            '⏭️ Skipping date $currentDate (not a working day or excluded)',
          );
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      debugPrint('💾 Saving generated slots (total: ${generatedSlots.length})');
      final savedSlots = await _saveGeneratedSlots(generatedSlots);
      if (savedSlots.isFailure) {
        debugPrint('❌ Failed saving slots: ${savedSlots.error}');
        throw savedSlots.error;
      }

      debugPrint('✅ Successfully saved ${savedSlots.data.length} slots');
      _eventBus.publish(SlotsGeneratedEvent(savedSlots.data));

      return savedSlots.data;
    }, 'generating appointment slots');
  }

  Future<Result<List<AppointmentSlot>>> _generateDaySlots({
    required String doctorId,
    required DateTime date,
    required Duration slotDuration,
    required TimeOfDay workDayStart,
    required TimeOfDay workDayEnd,
    List<TimeRange>? customHours,
  }) async {
    return ErrorHandler.guardAsync(() async {
      List<AppointmentSlot> daySlots = [];

      if (customHours != null && customHours.isNotEmpty) {
        // Generate slots for custom hours
        for (final timeRange in customHours) {
          daySlots.addAll(
            _generateSlotsForTimeRange(
              doctorId: doctorId,
              date: date,
              startTime: timeRange.start,
              endTime: timeRange.end,
              slotDuration: slotDuration,
            ),
          );
        }
      } else {
        // Generate slots for standard hours
        daySlots.addAll(
          _generateSlotsForTimeRange(
            doctorId: doctorId,
            date: date,
            startTime: workDayStart,
            endTime: workDayEnd,
            slotDuration: slotDuration,
          ),
        );
      }

      return daySlots;
    }, 'generating day slots');
  }

  List<AppointmentSlot> _generateSlotsForTimeRange({
    required String doctorId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Duration slotDuration,
  }) {
    List<AppointmentSlot> slots = [];
    DateTime currentSlotStart = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final rangeEnd = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    while (currentSlotStart.add(slotDuration).isBefore(rangeEnd) ||
        currentSlotStart.add(slotDuration).isAtSameMomentAs(rangeEnd)) {
      slots.add(
        AppointmentSlot(
          id: '', // Will be set by repository
          doctorId: doctorId,
          date: currentSlotStart,
          maxPatients: 1,
          bookedPatients: 0,
        ),
      );
      currentSlotStart = currentSlotStart.add(slotDuration);
    }

    return slots;
  }

  Future<Result<List<AppointmentSlot>>> _saveGeneratedSlots(
    List<AppointmentSlot> slots,
  ) async {
    debugPrint('📝 Starting _saveGeneratedSlots for ${slots.length} slots');
    return ErrorHandler.guardAsync(() async {
      List<AppointmentSlot> savedSlots = [];

      // First validate all slots
      for (final slot in slots) {
        debugPrint('🔍 Checking for existing slots at ${slot.date}');
        final existingSlotsResult = await _slotRepository.getByDoctorAndDate(
          slot.doctorId,
          slot.date,
        );

        if (existingSlotsResult.isFailure) {
          debugPrint(
            '❌ Error checking existing slots: ${existingSlotsResult.error}',
          );
          throw existingSlotsResult.error;
        }

        if (existingSlotsResult.data.isNotEmpty) {
          debugPrint('⚠️ Slot already exists for ${slot.date}, skipping');
          continue;
        }

        savedSlots.add(slot);
      }

      debugPrint('📊 Validated slots: ${savedSlots.length} to be saved');

      // Now save all valid slots
      List<AppointmentSlot> finalSavedSlots = [];
      for (final slot in savedSlots) {
        debugPrint('💾 Saving slot for ${slot.date}');
        final result = await _slotRepository.create(slot);
        if (result.isFailure) {
          debugPrint('❌ Failed to save slot for ${slot.date}: ${result.error}');
          continue;
        }
        finalSavedSlots.add(result.data);
      }

      if (finalSavedSlots.isEmpty) {
        debugPrint('❌ No slots were saved');
        throw 'No slots were generated. All slots already exist or failed to save.';
      }

      debugPrint('✅ Successfully saved ${finalSavedSlots.length} slots');
      return finalSavedSlots;
    }, 'saving generated slots');
  }

  bool _shouldGenerateForDay(
    DateTime date,
    List<WeekDay> workingDays,
    List<DateTime>? excludeDates,
  ) {
    final weekDay = WeekDay.values[date.weekday - 1];
    if (!workingDays.contains(weekDay)) {
      return false;
    }

    if (excludeDates != null) {
      return !excludeDates.any(
        (excludeDate) =>
            date.year == excludeDate.year &&
            date.month == excludeDate.month &&
            date.day == excludeDate.day,
      );
    }

    return true;
  }
}

/// Represents a time range with start and end times
class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange({required this.start, required this.end});
}

/// Represents days of the week
enum WeekDay { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

/// Event fired when slots are generated
class SlotsGeneratedEvent implements AppEvent {
  final List<AppointmentSlot> slots;
  SlotsGeneratedEvent(this.slots);

  @override
  String get eventType => 'SlotsGeneratedEvent';
}
