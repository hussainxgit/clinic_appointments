// lib/features/doctor/presentation/screens/doctor_form_screen.dart
import 'package:clinic_appointments/features/doctor/presentation/provider/doctor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../domain/entities/doctor.dart';

class DoctorFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  
  const DoctorFormScreen({super.key, this.isEditing = false});
  
  @override
  ConsumerState<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends ConsumerState<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Doctor _doctor;
  bool _isLoading = false;
  
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isAvailable = true;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (widget.isEditing) {
      // Initialize with existing doctor data
      final doctor = ModalRoute.of(context)!.settings.arguments as Doctor;
      _doctor = doctor;
      
      _nameController.text = doctor.name;
      _specialtyController.text = doctor.specialty;
      _phoneController.text = doctor.phoneNumber;
      _emailController.text = doctor.email ?? '';
      _bioController.text = doctor.bio ?? '';
      _isAvailable = doctor.isAvailable;
    } else {
      // Initialize with empty doctor
      _doctor = Doctor(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        specialty: '',
        phoneNumber: '',
      );
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }
  
  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    // Use Riverpod to access the doctor notifier
    final doctorNotifier = ref.read(doctorNotifierProvider.notifier);
    
    // Prepare updated doctor data
    final updatedDoctor = Doctor(
      id: _doctor.id,
      name: _nameController.text,
      specialty: _specialtyController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      isAvailable: _isAvailable,
      imageUrl: _doctor.imageUrl,
      socialMedia: _doctor.socialMedia,
    );
    
    // Use the appropriate method based on whether we're editing or creating
    final result = widget.isEditing
        ? await doctorNotifier.updateDoctor(updatedDoctor)
        : await doctorNotifier.addDoctor(updatedDoctor);
    
    setState(() {
      _isLoading = false;
    });
    
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Doctor updated successfully'
                : 'Doctor added successfully',
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
        title: Text(widget.isEditing ? 'Edit Doctor' : 'Add Doctor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter doctor name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter doctor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  hintText: 'Enter doctor specialty',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter doctor specialty';
                  }
                  return null;
                },
              ),
              // ... other form fields ...
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDoctor,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.isEditing ? 'Update Doctor' : 'Add Doctor'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}