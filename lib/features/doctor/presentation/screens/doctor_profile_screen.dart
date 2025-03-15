import 'package:clinic_appointments/core/navigation/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';
import '../../domain/entities/doctor.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  DateTime _selectedDate = DateTime.now();
  bool _isBookingAppointment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildAppBar(Doctor doctor, NavigationService navigationService) {
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
                content: Text(_isFavorite 
                  ? 'Added ${doctor.name} to favorites' 
                  : 'Removed ${doctor.name} from favorites'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share doctor profile
          },
        ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              navigationService.navigateTo(
                '/doctor/edit',
                arguments: doctor,
              );
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
                  )
                : Image.asset(
                    'assets/images/doctor_placeholder.jpg',
                    fit: BoxFit.cover,
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
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
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: doctor.isAvailable ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  doctor.isAvailable ? 'Available' : 'Unavailable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (doctor.bio != null && doctor.bio!.isNotEmpty)
            Text(
              doctor.bio!,
              style: const TextStyle(fontSize: 15),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Doctor doctor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.phone,
            label: 'Call',
            onTap: () {
              // Launch phone call
            },
          ),
          _buildActionButton(
            icon: Icons.message,
            label: 'Message',
            onTap: () {
              // Open messaging
            },
          ),
          _buildActionButton(
            icon: Icons.videocam,
            label: 'Video',
            onTap: () {
              // Start video consultation
            },
          ),
          _buildActionButton(
            icon: Icons.directions,
            label: 'Directions',
            onTap: () {
              // Open maps
            },
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(icon, color: Theme.of(context).primaryColor),
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
        Tab(text: 'Reviews'),
      ],
      indicatorColor: Theme.of(context).primaryColor,
      labelColor: Theme.of(context).primaryColor,
      unselectedLabelColor: Colors.grey,
    );
  }

  Widget _buildTabContent(Doctor doctor) {
    return SizedBox(
      height: 500, // Fixed height for tab content
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildAboutTab(doctor),
          _buildScheduleTab(doctor),
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
            title: 'Contact Information',
            children: [
              _buildInfoRow(Icons.phone, 'Phone', doctor.phoneNumber),
              if (doctor.email != null)
                _buildInfoRow(Icons.email, 'Email', doctor.email!),
            ],
          ),
          const Divider(),
          _buildInfoSection(
            title: 'Education & Training',
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
            children: [
              _buildInfoRow(Icons.language, 'Languages', 'English, Spanish'),
            ],
          ),
          const Divider(),
          _buildInfoSection(
            title: 'Insurance',
            children: [
              _buildInfoRow(
                Icons.health_and_safety,
                'Accepted Insurance',
                'Medicare, Blue Cross, Aetna, Cigna',
              ),
            ],
          ),
          if (doctor.socialMedia != null && doctor.socialMedia!.isNotEmpty) ...[
            const Divider(),
            _buildInfoSection(
              title: 'Social Media',
              children: doctor.socialMedia!.entries.map((entry) {
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
    final slots = ref.read(appointmentSlotNotifierProvider.notifier).getSlots(
      doctorId: doctor.id,
      date: _selectedDate,
    );
    
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
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
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
        
        // Availability calendar
        Expanded(
          child: slots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No available slots on ${DateFormat('EEEE, MMMM d').format(_selectedDate)}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Choose Another Date'),
                      ),
                    ],
                  ),
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
                      onTap: isAvailable ? () {
                        // Navigate to booking screen with this slot
                        _bookAppointment(slot);
                      } : null,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 40,
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
                                    color: isAvailable ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAvailable)
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReviewsTab(Doctor doctor) {
    // Mock reviews data
    final reviews = [
      {
        'name': 'John Smith',
        'rating': 5,
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'comment': 'Dr. ${doctor.name} was excellent! Very thorough and took time to explain everything.',
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
        'comment': 'Very knowledgeable and caring. Solved my eye problem quickly.',
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
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) => 
                      Icon(
                        index < 4 ? Icons.star : Icons.star_half,
                        color: Colors.amber,
                        size: 20,
                      )
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

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
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
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                name[0],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: List.generate(5, (index) => 
                Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                )
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
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _bookAppointment(dynamic slot) {
    // Navigate to booking confirmation
    ref.read(navigationServiceProvider).navigateTo(
      '/appointment/create',
      arguments: {
        'doctorId': slot.doctorId,
        'appointmentSlotId': slot.id,
        'dateTime': slot.date,
      },
    );
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                            DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
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
                          isLoading: _isBookingAppointment,
                          text: 'See Available Times',
                          onPressed: () {
                            setState(() {
                              _isBookingAppointment = true;
                            });
                            
                            // Simulate network delay
                            Future.delayed(const Duration(seconds: 1), () {
                              setState(() {
                                _isBookingAppointment = false;
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