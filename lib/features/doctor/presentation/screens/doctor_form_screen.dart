// lib/features/doctor/presentation/screens/doctor_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/error_display.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../../../core/ui/theme/app_theme.dart';
import '../../../doctor/domain/entities/doctor.dart';
import '../provider/doctor_notifier.dart';

class DoctorFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;

  const DoctorFormScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends ConsumerState<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Doctor _doctor;
  File? _imageFile;
  bool _isLoading = false;
  final bool _isUploading = false;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isAvailable = true;

  // Dropdown options
  final List<String> _specialties = [
    'General Ophthalmology',
    'Retina Specialist',
    'Cornea Specialist',
    'Glaucoma Specialist',
    'Pediatric Ophthalmology',
    'Oculoplastics',
    'Neuro-Ophthalmology',
    'Vision Therapy',
    'Low Vision Specialist',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.isEditing) {
      // Initialize with existing doctor data
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Doctor) {
        _doctor = args;

        _nameController.text = _doctor.name;
        _specialtyController.text = _doctor.specialty;
        _phoneController.text = _doctor.phoneNumber;
        _emailController.text = _doctor.email ?? '';
        _bioController.text = _doctor.bio ?? '';
        _isAvailable = _doctor.isAvailable;
      } else {
        // Handle error - arguments should contain doctor
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Doctor data not found')),
        );
        ref.read(navigationServiceProvider).goBack();
      }
    } else {
      // Initialize with empty doctor
      _doctor = Doctor(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '',
        specialty: '',
        phoneNumber: '',
        isAvailable: true,
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

  // Future<void> _pickImage() async {
  //   try {
  //     final picker = ImagePicker();
  //     final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  //     if (pickedFile != null) {
  //       setState(() {
  //         _imageFile = File(pickedFile.path);
  //         _isUploading = true;
  //       });

  //       // In a real app, you would upload the image to storage
  //       // and get back a URL to store with the doctor
  //       await Future.delayed(const Duration(seconds: 1)); // Simulate upload

  //       setState(() {
  //         _isUploading = false;
  //       });
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error picking image: $e')),
  //     );
  //     setState(() {
  //       _isUploading = false;
  //     });
  //   }
  // }

  Future<void> _saveDoctor() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final doctorNotifier = ref.read(doctorNotifierProvider.notifier);

      // Prepare updated doctor
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

      // Save doctor
      final result =
          widget.isEditing
              ? await doctorNotifier.updateDoctor(updatedDoctor)
              : await doctorNotifier.addDoctor(updatedDoctor);

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      // Process the result
      ErrorDisplay.handleResult(
        context: context,
        result: result,
        successMessage:
            widget.isEditing
                ? 'Doctor updated successfully'
                : 'Doctor added successfully',
        onSuccess: () {
          // Navigate back
          ref.read(navigationServiceProvider).goBack();
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;

      ErrorDisplay.showError(context, 'Unexpected error occurred');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Doctor' : 'Add Doctor'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
              color: Colors.red,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImageSection(),
              const SizedBox(height: 24),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildContactInfoSection(),
              const SizedBox(height: 24),
              _buildBioSection(),
              const SizedBox(height: 24),
              _buildAvailabilitySection(),
              const SizedBox(height: 32),
              LoadingButton(
                text: widget.isEditing ? 'Update Doctor' : 'Save Doctor',
                isLoading: _isLoading,
                onPressed: _saveDoctor,
                icon: Icons.save,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: _buildProfileImage(),
              ),
              // Positioned(
              //   right: 0,
              //   bottom: 0,
              //   child: Container(
              //     width: 36,
              //     height: 36,
              //     decoration: BoxDecoration(
              //       color: AppTheme.primaryColor,
              //       borderRadius: BorderRadius.circular(18),
              //       border: Border.all(color: Colors.white, width: 2),
              //     ),
              //     child: IconButton(
              //       padding: EdgeInsets.zero,
              //       icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              //       onPressed: _isUploading ? null : _pickImage,
              //     ),
              //   ),
              // ),
            ],
          ),
          if (_isUploading) ...[
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Uploading image...'),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.file(
          _imageFile!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else if (_doctor.imageUrl != null && _doctor.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: Image.network(
          _doctor.imageUrl!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  const Icon(Icons.person, size: 60, color: Colors.grey),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(60),
        child: const Icon(Icons.person, size: 60, color: Colors.grey),
      );
    }
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter doctor name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value:
              _specialtyController.text.isNotEmpty
                  ? _specialtyController.text
                  : null,
          decoration: const InputDecoration(
            labelText: 'Specialty',
            prefixIcon: Icon(Icons.medical_services),
            border: OutlineInputBorder(),
          ),
          items:
              _specialties.map((specialty) {
                return DropdownMenuItem<String>(
                  value: specialty,
                  child: Text(specialty),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              _specialtyController.text = value;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a specialty';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
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
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email (Optional)',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              // Simple email validation
              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegExp.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Professional Bio',
            hintText:
                'Brief description of professional experience and qualifications',
            prefixIcon: Icon(Icons.description),
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          minLines: 3,
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Available for appointments'),
          subtitle: Text(
            _isAvailable
                ? 'Doctor can receive new appointments'
                : 'Doctor cannot receive new appointments',
            style: TextStyle(color: _isAvailable ? Colors.green : Colors.red),
          ),
          value: _isAvailable,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) {
            setState(() {
              _isAvailable = value;
            });
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Doctor'),
            content: Text(
              'Are you sure you want to delete ${_doctor.name}? This action cannot be undone.',
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

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final doctorNotifier = ref.read(doctorNotifierProvider.notifier);
        final deleteResult = await doctorNotifier.deleteDoctor(_doctor.id);

        setState(() {
          _isLoading = false;
        });

        if (deleteResult.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Doctor deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          ref.read(navigationServiceProvider).goBack();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${deleteResult.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
