import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/clinic_service.dart';
import '../models/patient.dart';
import '../controller/patient_provider.dart';

class AddPatientDialog extends StatefulWidget {
  final Function(Patient)? onPatientAdded;

  const AddPatientDialog({super.key, this.onPatientAdded});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  // Form state
  DateTime? _dateOfBirth;
  PatientGender _gender = PatientGender.male;
  PatientStatus _status = PatientStatus.active;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    // Adjust Dialog height based on keyboard
    final viewInsets = mediaQuery.viewInsets.bottom;
    final DialogHeight = mediaQuery.size.height * 0.85;

    return Dialog(
      child: Container(
        height: DialogHeight + viewInsets,
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _buildDialogHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: viewInsets),
                    child: _buildForm(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_add_outlined),
          const SizedBox(width: 12),
          Text(
            'Add New Patient',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          _buildPersonalInfoSection(context),
          const SizedBox(height: 24),
          _buildContactInfoSection(context),
          const SizedBox(height: 24),
          _buildAdditionalInfoSection(context),
          const SizedBox(height: 32),
          _buildSubmitButton(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(
      BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          context,
          'Personal Information',
          Icons.person_outline,
        ),
        _buildTextFormField(
          label: 'Full Name',
          controller: _nameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }
            return null;
          },
          prefixIcon: Icons.person,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildGenderDropdown(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateOfBirthPicker(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          context,
          'Contact Information',
          Icons.contact_phone_outlined,
        ),
        _buildTextFormField(
          label: 'Phone Number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }

            // Check if phone already exists
            final patientProvider =
                Provider.of<PatientProvider>(context, listen: false);
            final existingPatient =
                patientProvider.findPatientByPhone(value.trim());
            if (existingPatient != null) {
              return 'A patient with this phone number already exists';
            }

            return null;
          },
          prefixIcon: Icons.phone,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          label: 'Email (Optional)',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email,
        ),
        const SizedBox(height: 16),
        _buildTextFormField(
          label: 'Address (Optional)',
          controller: _addressController,
          prefixIcon: Icons.home,
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          context,
          'Additional Information',
          Icons.notes_outlined,
        ),
        _buildStatusDropdown(),
        const SizedBox(height: 16),
        _buildTextFormField(
          label: 'Notes (Optional)',
          controller: _notesController,
          maxLines: 3,
          prefixIcon: Icons.note,
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: TextInputAction.next,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<PatientGender>(
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person_outline),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      value: _gender,
      items: PatientGender.values.map((gender) {
        return DropdownMenuItem<PatientGender>(
          value: gender,
          child: Text(gender == PatientGender.male ? 'Male' : 'Female'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _gender = value;
          });
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<PatientStatus>(
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.verified_user_outlined),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      value: _status,
      items: PatientStatus.values.map((status) {
        String displayText = status.toString().split('.').last;
        displayText = displayText[0].toUpperCase() + displayText.substring(1);

        return DropdownMenuItem<PatientStatus>(
          value: status,
          child: Text(displayText),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _status = value;
          });
        }
      },
    );
  }

  Widget _buildDateOfBirthPicker(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDateOfBirth(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: 'Date of Birth (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          controller: TextEditingController(
            text: _dateOfBirth != null
                ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                : '',
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'SELECT DATE OF BIRTH',
    );

    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _submitForm(context),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator()
            : const Text('ADD PATIENT'),
      ),
    );
  }

  Future<void> _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Create new patient
        final newPatient = Patient(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          gender: _gender,
          dateOfBirth: _dateOfBirth,
          registeredAt: DateTime.now(),
          status: _status,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        // Use clinic service instead of directly accessing the provider
        final clinicService =
            Provider.of<ClinicService>(context, listen: false);
        final result = await clinicService.addPatient(newPatient);

        if (result.isSuccess) {
          // Call the callback if provided
          if (widget.onPatientAdded != null) {
            widget.onPatientAdded!(newPatient);
          }

          // No need for explicit SnackBar here as the service handles notifications
          Navigator.of(context).pop(newPatient);
        } else {
          // Optional: Add specific error handling beyond what the service already does
          if (result.errorMessage?.contains('duplicate') ?? false) {
            // Special handling for duplicate patient
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Duplicate Patient'),
                content: const Text(
                    'A patient with this phone number already exists.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          // Note: General error notification is already handled by the service
        }
      } catch (e) {
        // This catch block is mostly for unexpected errors not handled by the service
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
