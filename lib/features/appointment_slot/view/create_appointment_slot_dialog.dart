import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/features/doctor/models/doctor.dart';
import 'package:clinic_appointments/features/appointment_slot/models/appointment_slot.dart';
import '../../../shared/provider/clinic_service.dart';

class CreateAppointmentSlot extends StatefulWidget {
  const CreateAppointmentSlot({super.key});

  @override
  State<CreateAppointmentSlot> createState() => _CreateAppointmentSlotState();
}

class _CreateAppointmentSlotState extends State<CreateAppointmentSlot> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  Doctor? _selectedDoctor;
  bool _isRecurring = false;
  String _repeatType = 'daily';
  int _numberOfSlots = 1;
  int _maxPatients = 1; // New field for maxPatients

  final List<String> _repeatTypes = ['daily', 'weekly'];

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null || _selectedDate == null) {
      _showError('Please fill all required fields');
      return;
    }

    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final slots = _generateSlots();

    try {
      for (final slot in slots) {
        clinicService.createAppointmentSlot(
          slot,
        );
      }
      // _showSuccess('Successfully created ${slots.length} appointment slots');
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Error creating slots: ${e.toString()}');
    }
  }

  List<AppointmentSlot> _generateSlots() {
    final slots = <AppointmentSlot>[];
    final baseDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    for (int i = 0; i < _numberOfSlots; i++) {
      final slotDate =
          _isRecurring ? _calculateRecurringDate(baseDate, i) : baseDate;

      slots.add(AppointmentSlot(
        id: DateTime.now().add(Duration(days: i)).toString(),
        doctorId: _selectedDoctor!.id,
        date: slotDate,
        maxPatients: _maxPatients, // Use the user-defined maxPatients
      ));
    }

    return slots;
  }

  DateTime _calculateRecurringDate(DateTime baseDate, int index) {
    switch (_repeatType) {
      case 'daily':
        return baseDate.add(Duration(days: index));
      case 'weekly':
        return baseDate.add(Duration(days: index * 7));
      default:
        return baseDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final doctors = clinicService.getDoctors();

    return AlertDialog(
      title: const Text('Create Appointment Slot(s)'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Doctor Selection
              DropdownButtonFormField<Doctor>(
                decoration: const InputDecoration(
                  labelText: 'Select Doctor',
                  border: OutlineInputBorder(),
                ),
                items: doctors.map((doctor) {
                  return DropdownMenuItem<Doctor>(
                    value: doctor,
                    child: Text(doctor.name),
                  );
                }).toList(),
                onChanged: (doctor) => setState(() => _selectedDoctor = doctor),
                validator: (value) => value == null ? 'Select a doctor' : null,
              ),
              const SizedBox(height: 16),

              // Date Selection
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: _selectedDate?.toLocal().toString().split(' ')[0],
                ),
                onTap: () => _selectDate(context),
                validator: (value) =>
                    _selectedDate == null ? 'Select date' : null,
              ),
              const SizedBox(height: 16),

              // Max Patients Input
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Max Patients per Slot',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _maxPatients.toString(),
                onChanged: (value) => _maxPatients = int.tryParse(value) ?? 1,
                validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                    ? 'Invalid number'
                    : null,
              ),
              const SizedBox(height: 16),

              // Recurring Slots Toggle
              SwitchListTile(
                title: const Text('Recurring Slots'),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
              ),

              // Recurring Options (only shown if recurring is enabled)
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: 'daily',
                  items: _repeatTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type.capitalize()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _repeatType = value!),
                  decoration: const InputDecoration(
                    labelText: 'Repeat Every',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Number of Appointment Slots',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: _numberOfSlots.toString(),
                  onChanged: (value) =>
                      _numberOfSlots = int.tryParse(value) ?? 1,
                  validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                      ? 'Invalid number'
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Create Slots'),
        ),
      ],
    );
  }
}
