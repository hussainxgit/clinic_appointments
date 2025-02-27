import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/features/doctor/models/doctor.dart';
import 'package:clinic_appointments/features/appointment_slot/models/appointment_slot.dart';
import '../../../shared/provider/clinic_service.dart';

class EditAppointmentSlot extends StatefulWidget {
  final AppointmentSlot initialSlot;

  const EditAppointmentSlot({
    super.key,
    required this.initialSlot,
  });

  @override
  State<EditAppointmentSlot> createState() => _EditAppointmentSlotState();
}

class _EditAppointmentSlotState extends State<EditAppointmentSlot> {
  late final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late Doctor? _selectedDoctor;
  late int _maxPatients;
  final bool _editAllInSeries = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialSlot.date;
    _maxPatients = widget.initialSlot.maxPatients;
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final originalDoctor = widget.initialSlot.doctorId;

    try {
      // Handle single slot edit
      if (!_editAllInSeries) {
        _updateSingleSlot(clinicService);
      } else {
        _updateSeriesSlots(clinicService, originalDoctor);
      }

      _showSuccess('Slot updated successfully');
      Navigator.of(context).pop();
    } catch (e) {
      _showError('Error updating slot: ${e.toString()}');
    }
  }

  void _updateSingleSlot(ClinicService clinicService) {
    final updatedSlot = widget.initialSlot.copyWith(
      date: _selectedDate,
      maxPatients: _maxPatients,
    );

    clinicService.updateAppointmentSlot(updatedSlot);
  }

  void _updateSeriesSlots(ClinicService clinicService, String originalDoctor) {
    final slots = clinicService
        .getAppointmentSlots(doctorId: originalDoctor)
        .where((slot) => slot.id.startsWith(widget.initialSlot.id))
        .toList();

    for (final slot in slots) {
      final updatedSlot = slot.copyWith(
          date:
              _selectedDate.add(slot.date.difference(widget.initialSlot.date)),
          maxPatients: _maxPatients,
          doctorId: _selectedDoctor!.id);
      clinicService.updateAppointmentSlot(updatedSlot);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final doctors = clinicService.getDoctors();
    final initialDoctor = doctors.firstWhere(
      (d) => d.id == widget.initialSlot.doctorId,
      orElse: () => doctors.first,
    );

    return AlertDialog(
      title: Text('Edit Appointment Slot'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Doctor Selection (disabled for series)
              DropdownButtonFormField<Doctor>(
                decoration: const InputDecoration(
                  labelText: 'Doctor',
                  border: OutlineInputBorder(),
                ),
                value: initialDoctor,
                items: doctors.map((doctor) {
                  return DropdownMenuItem<Doctor>(
                    value: doctor,
                    child: Text(doctor.name),
                  );
                }).toList(),
                onChanged: (doctor) {
                  setState(() => _selectedDoctor = doctor);
                },
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
                  text: _selectedDate.toLocal().toString().split(' ')[0],
                ),
                onTap: () => _selectDate(context),
                validator: (value) => null,
              ),
              const SizedBox(height: 16),

              // Max Patients
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Max Patients',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                initialValue: _maxPatients.toString(),
                onChanged: (value) => _maxPatients = int.tryParse(value) ?? 1,
                validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                    ? 'Invalid number'
                    : null,
              ),
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
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
