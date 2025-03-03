import 'package:clinic_appointments/features/doctor/models/doctor.dart';
import 'package:clinic_appointments/features/doctor/view/doctor_avatar.dart';
import 'package:clinic_appointments/features/doctor/controller/doctor_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  late Doctor _doctor;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  late TextEditingController _nameController;
  late TextEditingController _specialtyController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  
  @override
  void initState() {
    super.initState();
    _doctor = widget.doctor;
    _initControllers();
  }
  
  void _initControllers() {
    _nameController = TextEditingController(text: _doctor.name);
    _specialtyController = TextEditingController(text: _doctor.specialty);
    _emailController = TextEditingController(text: _doctor.email ?? '');
    _phoneController = TextEditingController(text: _doctor.phoneNumber);
    _bioController = TextEditingController(text: _doctor.bio ?? '');
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditing) {
        // Exiting edit mode without saving
        _isEditing = false;
        _initControllers(); // Reset controllers to original values
      } else {
        // Entering edit mode
        _isEditing = true;
      }
    });
  }
  
  void _saveChanges() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedDoctor = Doctor(
        id: _doctor.id,
        name: _nameController.text,
        specialty: _specialtyController.text,
        phoneNumber: _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
        imageUrl: _doctor.imageUrl,
        isAvailable: _doctor.isAvailable,
        socialMedia: _doctor.socialMedia,
      );
      
      try {
        // Update doctor in provider
        final doctorProvider = Provider.of<DoctorProvider>(context, listen: false);
        doctorProvider.updateDoctor(updatedDoctor);
        
        // Update local doctor state
        setState(() {
          _doctor = updatedDoctor;
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor profile updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating doctor: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel_outlined : Icons.edit_outlined),
            onPressed: _toggleEditMode,
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit Profile',
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(context),
              const SizedBox(height: 24),
              _buildAboutSection(context),
              const SizedBox(height: 24),
              _buildServicesSection(context),
              const SizedBox(height: 24),
              _buildSocialAndBookingSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DoctorAvatar(
              name: _doctor.name,
              imageUrl: _doctor.imageUrl,
              radius: 80,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isEditing
                      ? TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name is required';
                            }
                            if (value.length < 3) {
                              return 'Name must be at least 3 characters';
                            }
                            return null;
                          },
                        )
                      : Text(
                          _doctor.name,
                          style: theme.textTheme.titleLarge,
                        ),
                  const SizedBox(height: 4),
                  _isEditing
                      ? TextFormField(
                          controller: _specialtyController,
                          decoration: const InputDecoration(
                            labelText: 'Specialty',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Specialty is required';
                            }
                            if (value.length < 3) {
                              return 'Specialty must be at least 3 characters';
                            }
                            return null;
                          },
                        )
                      : Text(
                          _doctor.specialty,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              // Simple email validation
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value)) {
                                return 'Enter a valid email address';
                              }
                            }
                            return null;
                          },
                        )
                      : _buildContactInfo(
                          context, Icons.mail_outline, _doctor.email ?? 'No email provided'),
                  const SizedBox(height: 4),
                  _isEditing
                      ? TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone number is required';
                            }
                            if (value.length > 8) {
                              return 'Phone number cannot exceed 8 characters';
                            }
                            return null;
                          },
                        )
                      : _buildContactInfo(
                          context, Icons.phone_outlined, _doctor.phoneNumber),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isEditing
                ? TextFormField(
                    controller: _bioController,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                      hintText: 'Enter doctor\'s bio information',
                    ),
                    maxLines: 5,
                    minLines: 3,
                  )
                : Text(
                    _doctor.bio ?? "No bio available",
                    style: theme.textTheme.bodyMedium,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final theme = Theme.of(context);

    // Note: Service editing is not implemented in this example
    // A more complete implementation would allow adding/removing services

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Services & Pricing',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (_isEditing)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                    onPressed: () {
                      // This would open a dialog to add a new service
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service editing not implemented in this example')),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Demo service items - replace with actual data from doctor.services
            _buildServiceItem(context, 'General Consultation', '\$100'),
            _buildServiceItem(context, 'Follow-up Visit', '\$75'),
            _buildServiceItem(context, 'Specialist Referral', '\$50'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, String service, String price) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: theme.textTheme.bodyMedium,
          ),
          Row(
            children: [
              Chip(
                label: Text(
                  price,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: theme.colorScheme.secondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () {
                    // This would open a dialog to edit this service
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Service editing not implemented in this example')),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialAndBookingSection(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Connect',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (_isEditing)
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          onPressed: () {
                            // This would open a dialog to add social media
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Social media editing not implemented in this example')),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSocialButtons(context),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Schedule',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (_isEditing)
                        Switch(
                          value: _doctor.isAvailable,
                          onChanged: (value) {
                            setState(() {
                              // This would normally be part of the saved doctor data
                              _doctor = Doctor(
                                id: _doctor.id,
                                name: _doctor.name,
                                specialty: _doctor.specialty,
                                phoneNumber: _doctor.phoneNumber,
                                email: _doctor.email,
                                bio: _doctor.bio,
                                imageUrl: _doctor.imageUrl,
                                isAvailable: value,
                                socialMedia: _doctor.socialMedia,
                              );
                            });
                          },
                          activeColor: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      // Navigate to booking screen
                      if (!_doctor.isAvailable) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('This doctor is not currently available for appointments')),
                        );
                        return;
                      }
                      // Navigate to appointment booking screen
                    },
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: const Text('Book Appointment'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Toggle switch to mark doctor as ${_doctor.isAvailable ? 'unavailable' : 'available'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    final theme = Theme.of(context);

    // Get social media from doctor or use placeholders
    final socialMedia = _doctor.socialMedia ??
        {
          'facebook': 'url',
          'instagram': 'url',
          'twitter': 'url',
        };

    return Wrap(
      spacing: 8,
      children: [
        ...socialMedia.entries.map((entry) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: _getSocialIcon(entry.key),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.primary,
                ),
                tooltip: entry.key,
              ),
              if (_isEditing)
                Positioned(
                  right: -4,
                  top: -4,
                  child: GestureDetector(
                    onTap: () {
                      // This would remove the social media entry
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Social media editing not implemented in this example')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: theme.colorScheme.onError,
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Icon _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Icon(Icons.facebook);
      case 'twitter':
        return const Icon(Icons.message);
      case 'instagram':
        return const Icon(Icons.photo_camera);
      default:
        return const Icon(Icons.link);
    }
  }
}