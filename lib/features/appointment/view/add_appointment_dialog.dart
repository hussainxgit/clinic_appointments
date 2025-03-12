import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddAppointmentDialog extends StatefulWidget {
  const AddAppointmentDialog({super.key});

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? selectedDoctorId;
  DateTime? selectedDate;
  String? selectedSlotId;
  String status = 'scheduled';
  String paymentStatus = 'unpaid';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: colorScheme.surface,
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Appointment',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 24),

                // Patient information section
                _buildSectionHeader('Patient Information'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter patient phone number',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Phone number is required'
                      : null,
                  onChanged: (value) => clinicService.patientProvider
                      .autoFillNameFromPhone(value, _nameController),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Patient Name',
                  hint: 'Enter patient name',
                  prefixIcon: Icons.person,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Patient name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _notesController,
                  label: 'Notes (Optional)',
                  hint: 'Add any patient notes',
                  prefixIcon: Icons.note,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Appointment details section
                _buildSectionHeader('Appointment Details'),
                const SizedBox(height: 8),
                _buildDropdown<String>(
                  value: selectedDoctorId,
                  label: 'Doctor',
                  prefixIcon: Icons.medical_services,
                  hint: 'Select a doctor',
                  items: clinicService
                      .getAvailableDoctorsWithSlots()
                      .map((doctor) => DropdownMenuItem(
                          value: doctor.id, child: Text(doctor.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDoctorId = value;
                      selectedDate = null;
                      selectedSlotId = null;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Doctor selection is required' : null,
                ),
                const SizedBox(height: 16),
                _buildDateSelector(clinicService),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  value: status,
                  label: 'Status',
                  prefixIcon: Icons.event_note,
                  items: ['scheduled', 'completed', 'cancelled']
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.capitalize())))
                      .toList(),
                  onChanged: (value) => setState(() => status = value!),
                ),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  value: paymentStatus,
                  label: 'Payment Status',
                  prefixIcon: Icons.payment,
                  items: ['paid', 'unpaid']
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.capitalize())))
                      .toList(),
                  onChanged: (value) => setState(() => paymentStatus = value!),
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text('Cancel',
                          style: TextTheme().labelLarge?.copyWith(
                                color: colorScheme.primary,
                              )),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _saveAppointment,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimary,
                                strokeWidth: 2,
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    int maxLines = 1,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required IconData prefixIcon,
    String? hint,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
      hint: hint != null ? Text(hint) : null,
      icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
      isExpanded: true,
      dropdownColor: colorScheme.surfaceContainerLowest,
    );
  }

  Widget _buildDateSelector(ClinicService clinicService) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (selectedDoctorId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a doctor first'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final result = await clinicService.appointmentSlotProvider
              .selectSlotForDoctor(context, selectedDoctorId!);
          if (result != null) {
            setState(() {
              selectedDate = result['date'] as DateTime;
              selectedSlotId = result['slotId'] as String;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedDate == null
                      ? 'Select Date and Time'
                      : 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: selectedDate == null
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate == null || selectedSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final clinicService = Provider.of<ClinicService>(context, listen: false);

    try {
      await clinicService.createAppointmentFromForm(
        phone: _phoneController.text,
        name: _nameController.text,
        notes: _notesController.text,
        doctorId: selectedDoctorId!,
        dateTime: selectedDate!,
        appointmentSlotId: selectedSlotId!,
        status: status,
        paymentStatus: paymentStatus,
      );

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment created successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating appointment: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
