// lib/features/appointment_slot/presentation/screens/appointment_slot_form_screen.dart
import 'package:clinic_appointments/features/doctor/presentation/provider/doctor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/core_providers.dart';
import '../providers/appointment_slot_notifier.dart';
import '../../domain/entities/appointment_slot.dart';

class AppointmentSlotFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const AppointmentSlotFormScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<AppointmentSlotFormScreen> createState() =>
      _AppointmentSlotFormScreenState();
}

class _AppointmentSlotFormScreenState
    extends ConsumerState<AppointmentSlotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late AppointmentSlot _slot;
  bool _isLoading = false;

  String _selectedDoctorId = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final TextEditingController _maxPatientsController = TextEditingController(
    text: '10',
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.isEditing) {
      // Initialize with existing slot data
      _slot = ModalRoute.of(context)!.settings.arguments as AppointmentSlot;
      _selectedDoctorId = _slot.doctorId;
      _selectedDate = _slot.date;
      _selectedTime = TimeOfDay.fromDateTime(_slot.date);
      _maxPatientsController.text = _slot.maxPatients.toString();
    } else {
      // Generate a unique ID for the new slot
      _slot = AppointmentSlot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        doctorId: '',
        date: DateTime.now().add(const Duration(days: 1)),
        maxPatients: 10,
      );
    }
  }

  @override
  void dispose() {
    _maxPatientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Appointment Slot'
              : 'Create Appointment Slot',
        ),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _slot.bookedPatients > 0 ? null : _confirmDelete,
              color: _slot.bookedPatients > 0 ? Colors.grey : Colors.red,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDoctorDropdown(),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              _buildTimePicker(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxPatientsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Patients',
                  hintText: 'Enter the maximum number of patients',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter maximum patients';
                  }

                  final patients = int.tryParse(value);
                  if (patients == null || patients <= 0) {
                    return 'Please enter a valid number greater than 0';
                  }

                  if (widget.isEditing && patients < _slot.bookedPatients) {
                    return 'Cannot be less than booked patients (${_slot.bookedPatients})';
                  }

                  return null;
                },
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 16),

                // Read-only field for booked patients
                TextFormField(
                  initialValue: _slot.bookedPatients.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Currently Booked Patients',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  enabled: false,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAppointmentSlot,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                          widget.isEditing
                              ? 'Update Appointment Slot'
                              : 'Create Appointment Slot',
                          style: const TextStyle(fontSize: 16),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorDropdown() {
    final doctorState = ref.watch(doctorNotifierProvider);

    if (doctorState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final doctors = doctorState.doctors.where((d) => d.isAvailable).toList();
    if (doctors.isEmpty) {
      return const Card(
        color: Colors.amber,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No available doctors found. Please make sure at least one doctor is marked as available.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Set the initial doctor if not already set
    if (_selectedDoctorId.isEmpty && doctors.isNotEmpty) {
      _selectedDoctorId = doctors.first.id;
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Select Doctor',
        border: OutlineInputBorder(),
      ),
      value:
          doctors.any((d) => d.id == _selectedDoctorId)
              ? _selectedDoctorId
              : null,
      items:
          doctors
              .map(
                (doctor) => DropdownMenuItem<String>(
                  value: doctor.id,
                  child: Text(doctor.name),
                ),
              )
              .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDoctorId = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a doctor';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () => _selectTime(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Time',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.access_time),
        ),
        child: Text(_selectedTime.format(context)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime _combineDateAndTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _saveAppointmentSlot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final slotNotifier = ref.read(appointmentSlotNotifierProvider.notifier);

      // Create a slot with the form data
      final slotData = AppointmentSlot(
        id:
            widget.isEditing
                ? _slot.id
                : DateTime.now().millisecondsSinceEpoch.toString(),
        doctorId: _selectedDoctorId,
        date: _combineDateAndTime(),
        maxPatients: int.parse(_maxPatientsController.text),
        bookedPatients: widget.isEditing ? _slot.bookedPatients : 0,
        appointmentIds: widget.isEditing ? _slot.appointmentIds : [],
      );

      // Save the slot
      final result =
          widget.isEditing
              ? await slotNotifier.updateSlot(slotData.id, (_) => slotData)
              : await slotNotifier.addSlot(slotData);

      setState(() {
        _isLoading = false;
      });

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Appointment slot updated successfully'
                  : 'Appointment slot created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        ref.read(navigationServiceProvider).goBack();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Appointment Slot'),
          content: const Text(
            'Are you sure you want to delete this appointment slot? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      final slotNotifier = ref.read(appointmentSlotNotifierProvider.notifier);
      await slotNotifier.removeSlot(_slot.id);
      ref.read(navigationServiceProvider).goBack();
    }
  }
}
