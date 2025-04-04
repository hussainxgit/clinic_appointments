import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_form_section.dart';
import '../../domain/entities/appointment_slot.dart';
import '../../services/slot_generation_service.dart';
import '../providers/slot_generation_notifier.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/logger.dart';

class SlotGenerationForm extends ConsumerStatefulWidget {
  final String doctorId;
  final AppointmentSlot? existingSlot;
  final void Function(Result<List<AppointmentSlot>>) onGenerationComplete;

  const SlotGenerationForm({
    super.key,
    required this.doctorId,
    this.existingSlot,
    required this.onGenerationComplete,
  });

  @override
  ConsumerState<SlotGenerationForm> createState() => _SlotGenerationFormState();
}

class _SlotGenerationFormState extends ConsumerState<SlotGenerationForm> {
  final _logger = AppLogger(tag: 'SlotGenerationForm');
  final _formKey = GlobalKey<FormState>();

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
    _initializeFormData();
  }

  void _initializeFormData() {
    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _startDate = slot.date;
      _endDate = slot.date;
      _workDayStart = TimeOfDay.fromDateTime(slot.date);
      _workDayEnd = TimeOfDay.fromDateTime(
        slot.date.add(const Duration(minutes: 30)),
      );
    } else {
      _startDate = DateTime.now().add(const Duration(days: 1));
      _endDate = _startDate;
      _workDayStart = const TimeOfDay(hour: 9, minute: 0);
      _workDayEnd = const TimeOfDay(hour: 17, minute: 0);
    }
    _slotDuration = const Duration(minutes: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFormSection(
            title: 'Date Range',
            children: [_buildDateRangePicker()],
          ),
          CustomFormSection(
            title: 'Working Hours',
            children: [_buildTimeRangePicker(), _buildDurationPicker()],
          ),
          CustomFormSection(
            title: 'Schedule Configuration',
            children: [_buildWorkingDaysPicker(), _buildExcludeDatesPicker()],
          ),
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
          child: InkWell(
            onTap: () => _selectStartDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Start Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('MMM d, yyyy').format(_startDate)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectEndDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'End Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('MMM d, yyyy').format(_endDate)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRangePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectStartTime(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Work Day Start',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              child: Text(_workDayStart.format(context)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectEndTime(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Work Day End',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              child: Text(_workDayEnd.format(context)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationPicker() {
    return DropdownButtonFormField<Duration>(
      decoration: const InputDecoration(labelText: 'Slot Duration'),
      value: _slotDuration,
      items: _buildDurationItems(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _slotDuration = value);
        }
      },
    );
  }

  List<DropdownMenuItem<Duration>> _buildDurationItems() {
    return [15, 30, 45, 60].map((minutes) {
      return DropdownMenuItem(
        value: Duration(minutes: minutes),
        child: Text('$minutes minutes'),
      );
    }).toList();
  }

  Widget _buildWorkingDaysPicker() {
    return Wrap(
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
              onPressed: _addExcludeDate,
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
                  onDeleted: () => setState(() => _excludeDates.remove(date)),
                );
              }).toList(),
        ),
      ],
    );
  }

  Future<void> _addExcludeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: _startDate,
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() => _excludeDates.add(picked));
    }
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _generateSlots,
        child: const Text('Generate Slots'),
      ),
    );
  }

  Future<void> _generateSlots() async {
    if (!_formKey.currentState!.validate()) return;
    if (_workingDays.isEmpty) {
      _showError('Please select at least one working day');
      return;
    }

    _logger.info("Starting slot generation process");

    final result = await ref
        .read(slotGenerationNotifierProvider.notifier)
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
      widget.onGenerationComplete(result);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workDayStart,
    );

    if (picked != null && picked != _workDayStart) {
      setState(() {
        _workDayStart = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workDayEnd,
    );

    if (picked != null && picked != _workDayEnd) {
      setState(() {
        _workDayEnd = picked;
      });
    }
  }
}
