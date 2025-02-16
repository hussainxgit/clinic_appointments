import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../patient/models/patient.dart';
import '../models/appointment.dart';

class AddAppointmentDialog extends StatefulWidget {
  const AddAppointmentDialog({
    super.key,
  });

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String _status = 'scheduled';
  String _paymentStatus = 'unpaid';
  String _doctorId = '';
  String appointmentSlotId = '';

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_phoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_phoneChanged);
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _phoneChanged() {
    final existingPatient = Provider.of<ClinicService>(context, listen: false)
        .getPatients()
        .firstWhere(
          (p) => p.phone == _phoneController.text.trim(),
          orElse: () => Patient(
              id: '', name: '', phone: '', registeredAt: DateTime.now()),
        );

    if (existingPatient.id.isNotEmpty) {
      setState(() {
        _nameController.text = existingPatient.name; // Auto-fill name
      });
    }
  }

  Future<void> _selectDate(BuildContext context, String doctorId) async {
    final availabilities = Provider.of<ClinicService>(context, listen: false)
        .getAppointmentSlotsForDoctor(doctorId);

    final datesOnly =
        availabilities.map((availability) => availability.date).toList();

    // Ensure that availableDates is not empty before accessing its elements
    DateTime? initialDate = DateTime.now();
    if (datesOnly.isNotEmpty) {
      if (!datesOnly.contains(initialDate)) {
        initialDate = datesOnly.first; // Set to the first available date
      }

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime day) {
          return datesOnly.contains(day);
        },
      );

      if (picked != null && picked != _selectedDate) {
        appointmentSlotId = availabilities
            .firstWhere((availability) => availability.date == picked)
            .id;
        setState(() {
          _selectedDate = picked;
        });
      }
    } else {
      // Handle the case when there are no available dates
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No available dates for the selected doctor.')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final clinicService = Provider.of<ClinicService>(context, listen: false);

      // Check if patient already exists
      Patient patient = clinicService.patientProvider.patients.firstWhere(
        (p) => p.phone == _phoneController.text.trim(),
        orElse: () => Patient(
          id: DateTime.now().toString(), // Generate new ID
          name: _nameController.text,
          phone: _phoneController.text,
          registeredAt: DateTime.now(),
          notes: _notesController.text,
        ),
      );

      // If patient is new, add to provider
      if (!clinicService.patientProvider.patients.contains(patient)) {
        clinicService.addPatient(patient);
      }

      if (_selectedDate != null) {
        final appointment = Appointment(
          id: DateTime.now().toString(),
          patientId: patient.id,
          dateTime: _selectedDate!,
          status: _status,
          paymentStatus: _paymentStatus,
          appointmentSlotId: appointmentSlotId,
          doctorId: _doctorId, // Get selected doctor
        );
        Provider.of<ClinicService>(context, listen: false)
            .createAppointment(appointment);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Appointment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16.0,
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Patient Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Doctor',
                  border: OutlineInputBorder(),
                ),
                items: Provider.of<ClinicService>(context)
                    .getAvailableDoctors()
                    .map((doctor) => DropdownMenuItem(
                          value: doctor.id,
                          child: Text(doctor.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDate = null; // Reset selected date
                    appointmentSlotId = ''; // Reset availability ID
                    _doctorId = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a doctor';
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Select Appointment Date'
                      : 'Date: ${_selectedDate!.toLocal()}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, _doctorId),
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['scheduled', 'completed', 'cancelled']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Payment Status',
                  border: OutlineInputBorder(),
                ),
                items: ['paid', 'unpaid']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentStatus = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
