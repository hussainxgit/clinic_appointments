// lib/features/patient/presentation/screens/patient_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../domain/entities/patient.dart';
import '../providers/patient_notifier.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  
  const PatientFormScreen({super.key, this.isEditing = false});
  
  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Patient _patient;
  bool _isLoading = false;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Form values
  PatientGender _gender = PatientGender.male;
  DateTime? _dateOfBirth;
  PatientStatus _status = PatientStatus.active;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (widget.isEditing) {
      // Initialize with existing patient data
      final patient = ModalRoute.of(context)!.settings.arguments as Patient;
      _patient = patient;
      
      _nameController.text = patient.name;
      _phoneController.text = patient.phone;
      _emailController.text = patient.email ?? '';
      _addressController.text = patient.address ?? '';
      _notesController.text = patient.notes ?? '';
      _gender = patient.gender;
      _dateOfBirth = patient.dateOfBirth;
      _status = patient.status;
    } else {
      // Initialize with empty patient
      _patient = Patient(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        phone: '',
        registeredAt: DateTime.now(),
      );
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Use Riverpod to access the patient notifier
    final patientNotifier = ref.read(patientNotifierProvider.notifier);
    
    // Prepare updated patient data
    final updatedPatient = Patient(
      id: _patient.id,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
      gender: _gender,
      dateOfBirth: _dateOfBirth,
      registeredAt: _patient.registeredAt,
      status: _status,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      appointmentIds: _patient.appointmentIds,
    );
    
    // Use the appropriate method based on whether we're editing or creating
    final result = widget.isEditing
        ? await patientNotifier.updatePatient(updatedPatient)
        : await patientNotifier.addPatient(updatedPatient);
    
    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;
    
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Patient updated successfully'
                : 'Patient added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Use Riverpod to access the navigation service
      ref.read(navigationServiceProvider).goBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Patient' : 'Add Patient'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter patient full name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone),
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
              const SizedBox(height: 16),
              
              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Address field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  hintText: 'Enter address',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Gender selection
              Row(
                children: [
                  const Text('Gender:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  Radio<PatientGender>(
                    value: PatientGender.male,
                    groupValue: _gender,
                    onChanged: (PatientGender? value) {
                      if (value != null) {
                        setState(() {
                          _gender = value;
                        });
                      }
                    },
                  ),
                  const Text('Male'),
                  const SizedBox(width: 16),
                  Radio<PatientGender>(
                    value: PatientGender.female,
                    groupValue: _gender,
                    onChanged: (PatientGender? value) {
                      if (value != null) {
                        setState(() {
                          _gender = value;
                        });
                      }
                    },
                  ),
                  const Text('Female'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Date of birth picker
              InkWell(
                onTap: () => _selectDateOfBirth(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (Optional)',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _dateOfBirth == null
                        ? 'Select date of birth'
                        : DateFormat('MMM d, yyyy').format(_dateOfBirth!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Status selection
              if (widget.isEditing) ...[
                Row(
                  children: [
                    const Text('Status:', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 16),
                    Radio<PatientStatus>(
                      value: PatientStatus.active,
                      groupValue: _status,
                      onChanged: (PatientStatus? value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const Text('Active'),
                    const SizedBox(width: 16),
                    Radio<PatientStatus>(
                      value: PatientStatus.inactive,
                      groupValue: _status,
                      onChanged: (PatientStatus? value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                    const Text('Inactive'),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Enter additional notes',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Submit button
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  text: widget.isEditing ? 'Update Patient' : 'Add Patient',
                  isLoading: _isLoading,
                  icon: Icons.save,
                  onPressed: _savePatient,
                ),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete Patient', style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ],
            ],
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
    );
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }
  
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text(
          'Are you sure you want to delete this patient? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      final patientNotifier = ref.read(patientNotifierProvider.notifier);
      final result = await patientNotifier.deletePatient(_patient.id);
      
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(navigationServiceProvider).goBack();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}