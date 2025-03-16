// lib/features/doctor/presentation/screens/doctor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/theme/app_theme.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';
import '../../../appointment/presentation/providers/appointment_notifier.dart';
import '../../domain/entities/doctor.dart';
import '../provider/doctor_notifier.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = ModalRoute.of(context)!.settings.arguments as Doctor;
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(doctor, navigationService),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDoctorHeader(doctor),
                _buildActionButtons(doctor),
                _buildStatusIndicator(doctor),
                _buildTabBar(),
                _buildTabContent(doctor),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBookingBottomSheet(context, doctor),
        icon: const Icon(Icons.calendar_today),
        label: const Text('Book Appointment'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildAppBar(Doctor doctor, dynamic navigationService) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => navigationService.goBack(),
      ),
      actions: [
        IconButton(
          icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
          color: _isFavorite ? Colors.red : null,
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isFavorite
                      ? 'Added ${doctor.name} to favorites'
                      : 'Removed ${doctor.name} from favorites',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share doctor profile
            _shareDoctor(doctor);
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            navigationService.navigateTo('/doctor/edit', arguments: doctor);
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(doctor.name),
        background: Stack(
          fit: StackFit.expand,
          children: [
            doctor.imageUrl != null
                ? Image.network(
                  doctor.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Image.asset(
                        'assets/images/doctor_placeholder.jpg',
                        fit: BoxFit.cover,
                      ),
                )
                : Container(
                  color: AppTheme.primaryColor,
                  child: Center(
                    child: Text(
                      doctor.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 80, color: Colors.white),
                    ),
                  ),
                ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(Doctor doctor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.specialty,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const Text(
                          '4.8',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(' (124 reviews)'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (doctor.bio != null && doctor.bio!.isNotEmpty)
            Text(doctor.bio!, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(Doctor doctor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: doctor.isAvailable ? Colors.green : Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          doctor.isAvailable
              ? 'Available for Appointments'
              : 'Currently Unavailable',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Doctor doctor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.phone,
            label: 'Call',
            onTap: () => _callDoctor(doctor),
          ),
          _buildActionButton(
            icon: Icons.message,
            label: 'Message',
            onTap: () => _messageDoctor(doctor),
          ),
          _buildActionButton(
            icon: Icons.videocam,
            label: 'Video',
            onTap: () => _videoCallDoctor(doctor),
          ),
          _buildActionButton(
            icon: Icons.email,
            label: 'Email',
            onTap: () => _emailDoctor(doctor),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'About'),
        Tab(text: 'Schedule'),
        Tab(text: 'Patients'),
        Tab(text: 'Reviews'),
      ],
      labelColor: AppTheme.primaryColor,
      indicatorColor: AppTheme.primaryColor,
      unselectedLabelColor: Colors.grey,
    );
  }

  Widget _buildTabContent(Doctor doctor) {
    return SizedBox(
      height: 550, // Fixed height for tab content
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(doctor),
          _buildScheduleTab(doctor),
          _buildPatientsTab(doctor),
          _buildReviewsTab(doctor),
        ],
      ),
    );
  }

  Widget _buildAboutTab(Doctor doctor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: 'Specializations',
            icon: Icons.medical_services,
            content: 'Ophthalmology, Retina Surgery, Cataract Surgery',
          ),
          const Divider(),
          _buildInfoSection(
            title: 'Contact Information',
            icon: Icons.contact_phone,
            children: [
              _buildInfoRow(Icons.phone, 'Phone', doctor.phoneNumber),
              if (doctor.email != null)
                _buildInfoRow(Icons.email, 'Email', doctor.email!),
            ],
          ),
          const Divider(),
          _buildInfoSection(
            title: 'Education & Training',
            icon: Icons.school,
            children: [
              _buildInfoRow(
                Icons.school,
                'Medical School',
                'University Medical School',
              ),
              _buildInfoRow(
                Icons.workspace_premium,
                'Residency',
                'General Hospital Eye Clinic',
              ),
              _buildInfoRow(
                Icons.workspace_premium,
                'Fellowship',
                'Advanced Eye Institute',
              ),
            ],
          ),
          const Divider(),
          _buildInfoSection(
            title: 'Languages',
            icon: Icons.language,
            content: 'English, Spanish, Arabic',
          ),
          const Divider(),
          _buildInfoSection(
            title: 'Insurance',
            icon: Icons.health_and_safety,
            content: 'Medicare, Blue Cross, Aetna, Cigna',
          ),
          if (doctor.socialMedia != null && doctor.socialMedia!.isNotEmpty) ...[
            const Divider(),
            _buildInfoSection(
              title: 'Social Media',
              icon: Icons.public,
              children:
                  doctor.socialMedia!.entries.map((entry) {
                    IconData icon;
                    switch (entry.key.toLowerCase()) {
                      case 'twitter':
                        icon = Icons.webhook;
                        break;
                      case 'linkedin':
                        icon = Icons.link;
                        break;
                      case 'facebook':
                        icon = Icons.facebook;
                        break;
                      default:
                        icon = Icons.public;
                    }
                    return _buildInfoRow(icon, entry.key, entry.value);
                  }).toList(),
            ),
          ],
          const Divider(),
          _buildAvailabilityToggle(doctor),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    String? content,
    List<Widget>? children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (content != null)
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text(content, style: const TextStyle(fontSize: 16)),
            ),
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle(Doctor doctor) {
    final doctorNotifier = ref.read(doctorNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doctor Availability',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available for new appointments',
                style: TextStyle(fontSize: 16),
              ),
              Switch(
                value: doctor.isAvailable,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  _toggleDoctorAvailability(doctor, doctorNotifier);
                },
              ),
            ],
          ),
          Text(
            doctor.isAvailable
                ? 'Doctor is currently accepting new appointments'
                : 'Doctor is not accepting new appointments',
            style: TextStyle(
              color: doctor.isAvailable ? Colors.green : Colors.red,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(Doctor doctor) {
    final slotState = ref.watch(appointmentSlotNotifierProvider);

    if (slotState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter slots for this doctor
    final slots = ref
        .read(appointmentSlotNotifierProvider.notifier)
        .getSlots(doctorId: doctor.id, date: _selectedDate);

    return Column(
      children: [
        // Date selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Center(
                    child: Text(
                      DateFormat('EEEE, MMMM d').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
        ),

        // Add slot button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton.icon(
            onPressed: () => _addNewSlot(doctor),
            icon: const Icon(Icons.add),
            label: const Text('Add New Appointment Slot'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Availability calendar
        Expanded(
          child:
              slots.isEmpty
                  ? EmptyState(
                    message:
                        'No appointment slots on ${DateFormat('EEEE, MMMM d').format(_selectedDate)}',
                    icon: Icons.event_busy,
                    actionLabel: 'Add Slot',
                    onAction: () => _addNewSlot(doctor),
                  )
                  : ListView.builder(
                    itemCount: slots.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, index) {
                      final slot = slots[index];
                      final timeString = DateFormat('h:mm a').format(slot.date);
                      final isAvailable = !slot.isFullyBooked;

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isAvailable ? Colors.white : Colors.grey[100],
                        onTap: () => _editSlot(slot),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isAvailable ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    timeString,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    isAvailable
                                        ? '${slot.bookedPatients}/${slot.maxPatients} slots booked'
                                        : 'Fully booked',
                                    style: TextStyle(
                                      color:
                                          isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: AppTheme.accentColor,
                                  ),
                                  onPressed: () => _editSlot(slot),
                                  tooltip: 'Edit slot',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      slot.bookedPatients > 0
                                          ? null
                                          : () => _deleteSlot(slot),
                                  tooltip:
                                      slot.bookedPatients > 0
                                          ? 'Cannot delete booked slot'
                                          : 'Delete slot',
                                  color:
                                      slot.bookedPatients > 0
                                          ? Colors.grey
                                          : Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildPatientsTab(Doctor doctor) {
    final appointmentState = ref.watch(appointmentNotifierProvider);

    if (appointmentState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get appointments for this doctor
    final appointments =
        appointmentState.appointments.where((item) {
          final appointment = item['appointment'];
          return appointment.doctorId == doctor.id &&
              appointment.status == 'scheduled';
        }).toList();

    return appointments.isEmpty
        ? const EmptyState(
          message: 'No scheduled appointments for this doctor',
          icon: Icons.people_outline,
        )
        : ListView.builder(
          itemCount: appointments.length,
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (context, index) {
            final appointment = appointments[index]['appointment'];
            final patient = appointments[index]['patient'];

            return AppCard(
              onTap: () => _viewPatientDetails(patient),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: Text(
                      patient?.name.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient?.name ?? 'Unknown Patient',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'EEEE, MMMM d, yyyy • h:mm a',
                          ).format(appointment.dateTime),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            );
          },
        );
  }

  Widget _buildReviewsTab(Doctor doctor) {
    // Mock reviews data
    final reviews = [
      {
        'name': 'John Smith',
        'rating': 5,
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'comment':
            'Dr. ${doctor.name} was excellent! Very thorough and took time to explain everything.',
      },
      {
        'name': 'Sarah Johnson',
        'rating': 4,
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'comment': 'Good doctor, but had to wait a bit longer than expected.',
      },
      {
        'name': 'Michael Lee',
        'rating': 5,
        'date': DateTime.now().subtract(const Duration(days: 30)),
        'comment':
            'Very knowledgeable and caring. Solved my eye problem quickly.',
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Text(
                    '4.8',
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < 4 ? Icons.star : Icons.star_half,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text('124 reviews'),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.7),
                    _buildRatingBar(4, 0.2),
                    _buildRatingBar(3, 0.08),
                    _buildRatingBar(2, 0.015),
                    _buildRatingBar(1, 0.005),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: reviews.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewItem(
                name: review['name'] as String,
                rating: review['rating'] as int,
                date: review['date'] as DateTime,
                comment: review['comment'] as String,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int rating, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$rating'),
          const SizedBox(width: 4),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: Colors.amber,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem({
    required String name,
    required int rating,
    required DateTime date,
    required String comment,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
            ),
            Text(
              DateFormat('MMM d, yyyy').format(date),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(comment),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Action functions
  void _callDoctor(Doctor doctor) {
    // Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${doctor.name} at ${doctor.phoneNumber}...'),
      ),
    );
  }

  void _messageDoctor(Doctor doctor) {
    // Implement messaging functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening messages with ${doctor.name}...')),
    );
  }

  void _videoCallDoctor(Doctor doctor) {
    // Implement video call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting video call with ${doctor.name}...')),
    );
  }

  void _emailDoctor(Doctor doctor) {
    // Implement email functionality
    if (doctor.email != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Composing email to ${doctor.email}...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email address not available')),
      );
    }
  }

  void _shareDoctor(Doctor doctor) {
    // Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing ${doctor.name}\'s profile...')),
    );
  }

  void _addNewSlot(Doctor doctor) {
    // Navigate to slot creation screen
    ref
        .read(navigationServiceProvider)
        .navigateTo(
          '/appointment-slot/add',
          arguments: {'doctorId': doctor.id, 'date': _selectedDate},
        );
  }

  void _editSlot(dynamic slot) {
    // Navigate to slot edit screen
    ref
        .read(navigationServiceProvider)
        .navigateTo('/appointment-slot/edit', arguments: slot);
  }

  Future<void> _deleteSlot(dynamic slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Appointment Slot'),
            content: Text(
              'Are you sure you want to delete this appointment slot on ${DateFormat('EEE, MMM d').format(slot.date)} at ${DateFormat('h:mm a').format(slot.date)}?',
            ),
            actions: [
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

      final slotNotifier = ref.read(appointmentSlotNotifierProvider.notifier);
      final result = await slotNotifier.removeSlot(slot.id);

      setState(() {
        _isLoading = false;
      });

      if (result.isFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment slot deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _viewPatientDetails(dynamic patient) {
    if (patient != null) {
      ref
          .read(navigationServiceProvider)
          .navigateTo('/patient/details', arguments: patient);
    }
  }

  Future<void> _toggleDoctorAvailability(
    Doctor doctor,
    dynamic doctorNotifier,
  ) async {
    setState(() {
      _isLoading = true;
    });

    final updatedDoctor = doctor.copyWith(isAvailable: !doctor.isAvailable);

    final result = await doctorNotifier.updateDoctor(updatedDoctor);

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedDoctor.isAvailable
                ? 'Doctor marked as available'
                : 'Doctor marked as unavailable',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBookingBottomSheet(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book an Appointment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'When would you like to see the doctor?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, MMMM d, yyyy',
                            ).format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: LoadingButton(
                          isLoading: _isLoading,
                          text: 'See Available Times',
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });

                            // Simulate network delay
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                _isLoading = false;
                              });

                              // Close the sheet
                              Navigator.pop(context);

                              // Change to the schedule tab
                              _tabController.animateTo(1);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
