import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart'; // Assuming capitalize() is here
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddAppointmentDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  AddAppointmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context, listen: false);

    // Local UI state (not business logic)
    String? selectedDoctorId;
    DateTime? selectedDate;
    String? selectedSlotId;
    String status = 'scheduled';
    String paymentStatus = 'unpaid';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Appointment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter patient phone number',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.2),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                    onChanged: (value) => clinicService.patientProvider
                        .updateNameFromPhone(value, _nameController),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Patient Name',
                      hintText: 'Enter patient name',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.2),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (Optional)',
                      hintText: 'Add any patient notes',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.2),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDoctorId,
                    decoration: InputDecoration(
                      labelText: 'Doctor',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.2),
                    ),
                    items: clinicService
                        .getAvailableDoctors()
                        .map((doctor) => DropdownMenuItem(
                            value: doctor.id, child: Text(doctor.name)))
                        .toList(),
                    onChanged: (value) => setState(() {
                      selectedDoctorId = value;
                      selectedDate = null;
                      selectedSlotId = null;
                    }),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.2),
                    title: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    trailing: Icon(Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary),
                    onTap: () async {
                      if (selectedDoctorId != null) {
                        final result = await clinicService
                            .appointmentSlotProvider
                            .selectSlotForDoctor(context, selectedDoctorId!);
                        if (result != null) {
                          setState(() {
                            selectedDate = result['date'] as DateTime;
                            selectedSlotId = result['slotId'] as String;
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.2),
                    ),
                    items: ['scheduled', 'completed', 'cancelled']
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s.capitalize())))
                        .toList(),
                    onChanged: (value) => setState(() => status = value!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: paymentStatus,
                    decoration: InputDecoration(
                      labelText: 'Payment Status',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.2),
                    ),
                    items: ['paid', 'unpaid']
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s.capitalize())))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => paymentStatus = value!),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                selectedDate != null &&
                selectedSlotId != null &&
                selectedDoctorId != null) {
              clinicService
                  .createAppointmentFromForm(
                    phone: _phoneController.text,
                    name: _nameController.text,
                    notes: _notesController.text,
                    doctorId: selectedDoctorId!,
                    dateTime: selectedDate!,
                    appointmentSlotId: selectedSlotId!,
                    status: status,
                    paymentStatus: paymentStatus,
                  )
                  .then((_) => Navigator.of(context).pop());
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
