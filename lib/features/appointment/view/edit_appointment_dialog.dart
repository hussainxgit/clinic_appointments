import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';

class EditAppointmentDialog extends StatefulWidget {
  final Appointment appointment;
  final String patientName;

  const EditAppointmentDialog({
    super.key,
    required this.appointment,
    required this.patientName,
  });

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime? _selectedDate;
  late String _status;
  late String _paymentStatus;
  late String _doctorId;
  late String _availabilityId;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and values with the existing appointment data
    _selectedDate = widget.appointment.dateTime;
    _status = widget.appointment.status;
    _paymentStatus = widget.appointment.paymentStatus;
    _doctorId = widget.appointment.doctorId;
    _availabilityId = widget.appointment.appointmentSlotId;
  }

  Future<void> _selectDate(BuildContext context, String doctorId) async {
    final availabilities = Provider.of<ClinicService>(context, listen: false)
        .getAppointmentSlots(doctorId: doctorId);

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
        firstDate: initialDate,
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime day) {
          return datesOnly.contains(day);
        },
      );

      if (picked != null && picked != _selectedDate) {
        _availabilityId = availabilities
            .firstWhere((availability) => availability.date == picked)
            .id;
        setState(() {
          _selectedDate = picked;
        });
      }
    } else {
      // Handle the case when there are no available dates
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No available dates for the selected doctor.')),
      );
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_availabilityId.isEmpty) {
        // Show a message prompting the user to select a doctor
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date.')),
        );
        return;
      }

      // Update the appointment details
      final updatedAppointment = Appointment(
        id: widget.appointment.id,
        patientId: widget.appointment.patientId,
        dateTime: _selectedDate!,
        status: _status,
        paymentStatus: _paymentStatus,
        doctorId: widget.appointment.doctorId,
        appointmentSlotId: _availabilityId,
      );

      // Update the patient and appointment in the providers
      Provider.of<ClinicService>(context, listen: false)
          .updateAppointmentAndPatient(
        updatedAppointment,
        widget.appointment,
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Appointment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16.0,
            children: [
              Text(
                widget.patientName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              DropdownButtonFormField<String>(
                value: _doctorId,
                decoration: const InputDecoration(
                  labelText: 'Doctor',
                  border: OutlineInputBorder(),
                ),
                items: Provider.of<ClinicService>(context, listen: false)
                    .getAvailableDoctors()
                    .map((doctor) => DropdownMenuItem(
                          value: doctor.id,
                          child: Text(doctor.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDate = null; // Reset selected date
                    _availabilityId = ''; // Reset availability ID
                    _doctorId = value!;
                  });
                },
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
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Select Appointment Date'
                      : 'Date: ${_selectedDate!.toLocal()}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, _doctorId),
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
