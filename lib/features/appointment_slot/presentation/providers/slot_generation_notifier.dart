import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/slot_generation_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/appointment_slot.dart';

part 'slot_generation_notifier.g.dart';

@riverpod
class SlotGenerationNotifier extends _$SlotGenerationNotifier {
  @override
  FutureOr<void> build() async {}

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
    state = const AsyncLoading();

    final result = await ref
        .read(slotGenerationServiceProvider)
        .generateSlots(
          SlotGenerationConfig(
            doctorId: doctorId,
            startDate: startDate,
            endDate: endDate,
            slotDuration: slotDuration,
            workingDays: workingDays,
            workDayStart: workDayStart,
            workDayEnd: workDayEnd,
          ),
        );

    state = AsyncData(null);
    return result;
  }
}
