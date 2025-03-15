import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../presentation/provider/doctor_notifier.dart';
import '../../domain/entities/doctor.dart';

class DoctorsScreen extends ConsumerStatefulWidget {
  const DoctorsScreen({super.key});

  @override
  ConsumerState<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends ConsumerState<DoctorsScreen> {
  String _searchQuery = '';
  String? _selectedSpecialty;
  String? _selectedGender;
  bool _onlyShowAvailable = true;
  final List<Doctor> _selectedDoctors = [];
  final List<String> _favoriteIds = [];
  String _sortBy = 'name'; // Default sort

  final TextEditingController _searchController = TextEditingController();
  final List<String> _specialties = [
    'General Ophthalmology',
    'Retina',
    'Cornea',
    'Pediatric',
    'Glaucoma',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorNotifierProvider);
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Show favorites
            },
            tooltip: 'Favorite Doctors',
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed:
                _selectedDoctors.length >= 2
                    ? () {
                      // Open comparison view
                    }
                    : null,
            tooltip: 'Compare Selected Doctors',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              navigationService.navigateTo('/doctor/add');
            },
            tooltip: 'Add Doctor',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with voice input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () {
                        // Implement voice search
                      },
                      tooltip: 'Search by voice',
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Specialty filter
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DropdownButton<String>(
                    hint: const Text('Specialty'),
                    value: _selectedSpecialty,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Specialties'),
                      ),
                      ..._specialties.map(
                        (specialty) => DropdownMenuItem<String>(
                          value: specialty,
                          child: Text(specialty),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecialty = value;
                      });
                    },
                  ),
                ),

                // Gender filter
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DropdownButton<String>(
                    hint: const Text('Gender'),
                    value: _selectedGender,
                    items: const [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Any Gender'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'male',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'female',
                        child: Text('Female'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                  ),
                ),

                // Availability filter
                FilterChip(
                  label: const Text('Available Now'),
                  selected: _onlyShowAvailable,
                  onSelected: (selected) {
                    setState(() {
                      _onlyShowAvailable = selected;
                    });
                  },
                ),

                const SizedBox(width: 8),

                // Sort options
                DropdownButton<String>(
                  hint: const Text('Sort By'),
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'name',
                      child: Text('Name'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'experience',
                      child: Text('Experience'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'availability',
                      child: Text('Availability'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                    }
                  },
                ),

                const SizedBox(width: 8),

                TextButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: const Text('More Filters'),
                  onPressed: () {
                    _showFilterBottomSheet(context);
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Doctor list
          Expanded(child: _buildDoctorList(doctorState)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Find next available appointment
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Finding next available appointment...'),
            ),
          );
        },
        icon: const Icon(Icons.calendar_today),
        label: const Text('Next Available'),
        tooltip: 'Book next available appointment',
      ),
    );
  }

  Widget _buildDoctorList(DoctorState doctorState) {
    if (doctorState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (doctorState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: ${doctorState.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      ref
                          .read(doctorNotifierProvider.notifier)
                          .refreshDoctors(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Apply filters
    final doctors = _filterDoctors(doctorState.doctors);

    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No doctors match your filters'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _selectedSpecialty = null;
                  _selectedGender = null;
                  _onlyShowAvailable = true;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctors[index];
        return _buildDoctorCard(doctor);
      },
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundImage:
                  doctor.imageUrl != null
                      ? NetworkImage(doctor.imageUrl!)
                      : null,
              child:
                  doctor.imageUrl == null
                      ? Text(doctor.name.substring(0, 1))
                      : null,
            ),
            if (doctor.isAvailable)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                doctor.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(
                _favoriteIds.contains(doctor.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _favoriteIds.contains(doctor.id) ? Colors.red : null,
              ),
              onPressed: () {
                setState(() {
                  if (_favoriteIds.contains(doctor.id)) {
                    _favoriteIds.remove(doctor.id);
                  } else {
                    _favoriteIds.add(doctor.id);
                  }
                });
              },
              tooltip: 'Add to favorites',
            ),
            Checkbox(
              value: _selectedDoctors.contains(doctor),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    if (_selectedDoctors.length < 3) {
                      _selectedDoctors.add(doctor);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You can compare up to 3 doctors'),
                        ),
                      );
                    }
                  } else {
                    _selectedDoctors.remove(doctor);
                  }
                });
              },
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doctor.specialty),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  doctor.isAvailable ? Icons.check_circle : Icons.cancel,
                  color: doctor.isAvailable ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  doctor.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    color: doctor.isAvailable ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doctor.bio != null && doctor.bio!.isNotEmpty)
                  Text(doctor.bio!),

                const SizedBox(height: 16),

                // Contact information
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16),
                    const SizedBox(width: 8),
                    Text(doctor.phoneNumber),
                    const SizedBox(width: 16),
                    if (doctor.email != null) ...[
                      const Icon(Icons.email, size: 16),
                      const SizedBox(width: 8),
                      Text(doctor.email!),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Next available appointments
                Text(
                  'Next Available Appointments:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: [
                    _buildAppointmentChip('Today, 2:00 PM'),
                    _buildAppointmentChip('Tomorrow, 10:30 AM'),
                    _buildAppointmentChip('Wed, Mar 17, 3:15 PM'),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Doctor Profile'),
                      onPressed: () {
                        // Navigate to doctor details
                        final navigationService = ref.read(
                          navigationServiceProvider,
                        );

                        navigationService.navigateTo(
                          '/doctor/profile',
                          arguments: doctor,
                        );
                      },
                    ),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Book Appointment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed:
                          doctor.isAvailable
                              ? () {
                                // Navigate to appointment booking
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Booking appointment with ${doctor.name}...',
                                    ),
                                  ),
                                );
                              }
                              : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentChip(String timeSlot) {
    return ActionChip(
      label: Text(timeSlot),
      avatar: const Icon(Icons.access_time, size: 16),
      onPressed: () {
        // Book this specific time slot
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking appointment for $timeSlot...')),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Advanced Filters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Experience slider
                    const Text('Years of Experience'),
                    RangeSlider(
                      values: const RangeValues(0, 30),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      labels: const RangeLabels('0 years', '30+ years'),
                      onChanged: (RangeValues values) {
                        // Update experience filter
                      },
                    ),

                    const SizedBox(height: 16),

                    // Languages
                    const Text('Languages'),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('English'),
                          selected: true,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Spanish'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('French'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Arabic'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Insurance
                    const Text('Insurance Accepted'),
                    const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search insurance providers',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Medicare'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Blue Cross'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                        FilterChip(
                          label: const Text('Aetna'),
                          selected: false,
                          onSelected: (selected) {},
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Clear all filters
                            Navigator.pop(context);
                          },
                          child: const Text('Reset All'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Apply filters
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Doctor> _filterDoctors(List<Doctor> doctors) {
    return doctors.where((doctor) {
      // Apply search filter
      final nameMatch =
          _searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(_searchQuery.toLowerCase());

      // Apply specialty filter
      final specialtyMatch =
          _selectedSpecialty == null || doctor.specialty == _selectedSpecialty;

      // Apply gender filter (assuming there's a gender field)
      final genderMatch = _selectedGender == null;

      // Apply availability filter
      final availabilityMatch = !_onlyShowAvailable || doctor.isAvailable;

      return nameMatch && specialtyMatch && genderMatch && availabilityMatch;
    }).toList();
  }
}
