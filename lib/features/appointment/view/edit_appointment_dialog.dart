import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize values with the existing appointment data
    _selectedDate = widget.appointment.dateTime;
    _status = widget.appointment.status;
    _paymentStatus = widget.appointment.paymentStatus;
    _doctorId = widget.appointment.doctorId;
    _availabilityId = widget.appointment.appointmentSlotId;
  }

  Future<void> _selectDate(BuildContext context, String doctorId) async {
    setState(() => _isLoading = true);

    try {
      final availabilities = Provider.of<ClinicService>(context, listen: false)
          .getAppointmentSlots(doctorId: doctorId);

      if (availabilities.isEmpty) {
        _showSnackBar('No available dates for the selected doctor.');
        return;
      }

      final datesOnly =
          availabilities.map((availability) => availability.date).toList();

      // Find a suitable initial date
      DateTime initialDate =
          datesOnly.contains(_selectedDate) ? _selectedDate! : datesOnly.first;

      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime.now().subtract(const Duration(days: 1)),
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime day) => datesOnly.contains(day),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme, dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surface),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        _availabilityId = availabilities
            .firstWhere((availability) => availability.date == picked)
            .id;
        setState(() {
          _selectedDate = picked;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_availabilityId.isEmpty) {
        _showSnackBar('Please select a date.');
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Update the appointment details
        final updatedAppointment = Appointment(
          id: widget.appointment.id,
          patientId: widget.appointment.patientId,
          dateTime: _selectedDate!,
          status: _status,
          paymentStatus: _paymentStatus,
          doctorId: _doctorId,
          appointmentSlotId: _availabilityId,
        );

        // Update the patient and appointment in the providers
        Provider.of<ClinicService>(context, listen: false)
            .updateAppointmentAndPatient(
          updatedAppointment,
          widget.appointment,
        );

        Navigator.of(context).pop(true);
      } catch (e) {
        _showSnackBar('Failed to update appointment: ${e.toString()}');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: colorScheme.surface,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Update Appointment',
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Chip(
                      label: Text(
                        widget.patientName,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Doctor selection
                  _buildDropdown(
                    label: 'Doctor',
                    icon: Icons.medical_services_outlined,
                    value: _doctorId,
                    items: Provider.of<ClinicService>(context, listen: false)
                        .getAvailableDoctorsWithSlots()
                        .map((doctor) => DropdownMenuItem(
                              value: doctor.id,
                              child: Text(doctor.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDate = null;
                        _availabilityId = '';
                        _doctorId = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Status selection
                  _buildDropdown(
                    label: 'Status',
                    icon: Icons.event_available_outlined,
                    value: _status,
                    items: [
                      _buildDropdownItem('scheduled', colorScheme.primary),
                      _buildDropdownItem('completed', Colors.green),
                      _buildDropdownItem('cancelled', Colors.red),
                    ],
                    onChanged: (value) => setState(() => _status = value!),
                  ),
                  const SizedBox(height: 16),

                  // Payment status selection
                  _buildDropdown(
                    label: 'Payment Status',
                    icon: Icons.payment_outlined,
                    value: _paymentStatus,
                    items: [
                      _buildDropdownItem('paid', Colors.green),
                      _buildDropdownItem('unpaid', Colors.orange),
                    ],
                    onChanged: (value) =>
                        setState(() => _paymentStatus = value!),
                  ),
                  const SizedBox(height: 16),

                  // Date selection
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: colorScheme.outline.withValues(alpha:0.5)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _doctorId.isNotEmpty
                          ? _selectDate(context, _doctorId)
                          : _showSnackBar('Please select a doctor first'),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Select Appointment Date'
                                    : 'Date: ${DateFormat.yMMMEd().format(_selectedDate!)}',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: _selectedDate == null
                                      ? colorScheme.onSurfaceVariant
                                          .withValues(alpha:0.8)
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _buildDropdownItem(String value, Color? chipColor) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: chipColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value[0].toUpperCase() + value.substring(1),
            style: TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha:0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha:0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      icon: Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      items: items,
      onChanged: _isLoading ? null : onChanged,
    );
  }
}
