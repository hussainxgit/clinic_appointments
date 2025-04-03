import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/appointment_slot.dart';
import '../../services/slot_generation_service.dart';
import '../controllers/slot_generation_controller.dart';

class SlotGenerationForm extends ConsumerStatefulWidget {
  final String doctorId;
  final DateTime? initialDate;
  final AppointmentSlot? existingSlot;

  const SlotGenerationForm({
    super.key,
    required this.doctorId,
    this.initialDate,
    this.existingSlot,
  });

  @override
  ConsumerState<SlotGenerationForm> createState() => _SlotGenerationFormState();
}

class _SlotGenerationFormState extends ConsumerState<SlotGenerationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _workDayStart;
  late TimeOfDay _workDayEnd;
  late Duration _slotDuration;
  final Set<WeekDay> _workingDays = {};
  final List<DateTime> _excludeDates = [];

  @override
  void initState() {
    super.initState();

    // Initialize with existing slot data if available
    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _startDate = slot.date;
      _endDate = slot.date; // Single slot editing
      _workDayStart = TimeOfDay.fromDateTime(slot.date);
      _workDayEnd = TimeOfDay.fromDateTime(
        slot.date.add(const Duration(minutes: 30)), // Default duration
      );
      _slotDuration = const Duration(minutes: 30);
      _workingDays.add(_getWeekDay(slot.date.weekday));
    } else {
      // Initialize with default or provided values
      _startDate = widget.initialDate ?? DateTime.now();
      _endDate = _startDate.add(const Duration(days: 30));
      _workDayStart = const TimeOfDay(hour: 9, minute: 0);
      _workDayEnd = const TimeOfDay(hour: 17, minute: 0);
      _slotDuration = const Duration(minutes: 30);
      _workingDays.addAll([
        WeekDay.monday,
        WeekDay.tuesday,
        WeekDay.wednesday,
        WeekDay.thursday,
        WeekDay.friday,
      ]);
    }
  }

  WeekDay _getWeekDay(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return WeekDay.monday;
      case DateTime.tuesday:
        return WeekDay.tuesday;
      case DateTime.wednesday:
        return WeekDay.wednesday;
      case DateTime.thursday:
        return WeekDay.thursday;
      case DateTime.friday:
        return WeekDay.friday;
      case DateTime.saturday:
        return WeekDay.saturday;
      case DateTime.sunday:
        return WeekDay.sunday;
      default:
        throw ArgumentError('Invalid weekday: $weekday');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangePicker(),
          const SizedBox(height: 16),
          _buildTimeRangePicker(),
          const SizedBox(height: 16),
          _buildDurationPicker(),
          const SizedBox(height: 16),
          _buildWorkingDaysPicker(),
          const SizedBox(height: 16),
          _buildExcludeDatesPicker(),
          const SizedBox(height: 24),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Start Date'),
            readOnly: true,
            controller: TextEditingController(
              text: _startDate.toString().split(' ')[0],
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                  // Ensure end date is not before start date
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate;
                  }
                });
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'End Date'),
            readOnly: true,
            controller: TextEditingController(
              text: _endDate.toString().split(' ')[0],
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    _endDate.isBefore(_startDate) ? _startDate : _endDate,
                firstDate: _startDate,
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _endDate = picked);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangePicker() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Work Day Start'),
            readOnly: true,
            controller: TextEditingController(
              text: _workDayStart.format(context),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _workDayStart,
              );
              if (picked != null) {
                setState(() => _workDayStart = picked);
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(labelText: 'Work Day End'),
            readOnly: true,
            controller: TextEditingController(
              text: _workDayEnd.format(context),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _workDayEnd,
              );
              if (picked != null) {
                setState(() => _workDayEnd = picked);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return DropdownButtonFormField<Duration>(
      decoration: const InputDecoration(labelText: 'Slot Duration'),
      value: _slotDuration,
      items: [
        DropdownMenuItem(
          value: const Duration(minutes: 15),
          child: const Text('15 minutes'),
        ),
        DropdownMenuItem(
          value: const Duration(minutes: 30),
          child: const Text('30 minutes'),
        ),
        DropdownMenuItem(
          value: const Duration(minutes: 45),
          child: const Text('45 minutes'),
        ),
        DropdownMenuItem(
          value: const Duration(minutes: 60),
          child: const Text('60 minutes'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _slotDuration = value);
        }
      },
    );
  }

  Widget _buildWorkingDaysPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Working Days'),
        Wrap(
          spacing: 8,
          children:
              WeekDay.values.map((day) {
                return FilterChip(
                  label: Text(day.name),
                  selected: _workingDays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _workingDays.add(day);
                      } else {
                        _workingDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildExcludeDatesPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Excluded Dates'),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: _startDate,
                  lastDate: _endDate,
                );
                if (picked != null) {
                  setState(() => _excludeDates.add(picked));
                }
              },
              child: const Text('Add Date'),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children:
              _excludeDates.map((date) {
                return Chip(
                  label: Text(date.toString().split(' ')[0]),
                  onDeleted: () {
                    setState(() => _excludeDates.remove(date));
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _generateSlots,
        child:
            _isLoading
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Generating Slots...'),
                  ],
                )
                : const Text('Generate Slots'),
      ),
    );
  }

  void _generateSlots() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      debugPrint('🎯 Starting slot generation with parameters:');
      debugPrint('Doctor ID: ${widget.doctorId}');
      debugPrint('Start Date: $_startDate');
      debugPrint('End Date: $_endDate');
      debugPrint('Slot Duration: $_slotDuration');
      debugPrint('Working Days: $_workingDays');
      debugPrint('Work Day Start: $_workDayStart');
      debugPrint('Work Day End: $_workDayEnd');
      debugPrint('Exclude Dates: $_excludeDates');

      final result = await ref
          .read(slotGenerationControllerProvider.notifier)
          .generateSlots(
            doctorId: widget.doctorId,
            startDate: _startDate,
            endDate: _endDate,
            slotDuration: _slotDuration,
            workingDays: _workingDays.toList(),
            workDayStart: _workDayStart,
            workDayEnd: _workDayEnd,
            excludeDates: _excludeDates,
          );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.isSuccess) {
          debugPrint('✅ Successfully generated ${result.data.length} slots');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully generated ${result.data.length} new slots',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          debugPrint('❌ Error generating slots: ${result.error}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
