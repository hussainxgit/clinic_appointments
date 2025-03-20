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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSpecialty;
  bool _onlyShowAvailable = false;
  String _sortBy = 'name';

  static const List<String> _specialties = [
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
        title: const Text('Doctors'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filter',
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(context),
            const SizedBox(height: 16),
            Expanded(child: _buildDoctorList(doctorState)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigationService.navigateTo('/doctor/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search doctors',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildDoctorList(DoctorState doctorState) {
    if (doctorState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (doctorState.error != null) {
      return _buildErrorState(doctorState.error!);
    }

    final filteredDoctors = _filterAndSortDoctors(doctorState.doctors);

    if (filteredDoctors.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(doctorNotifierProvider.notifier).refreshDoctors(),
      child: ListView.separated(
        itemCount: filteredDoctors.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildDoctorCard(filteredDoctors[index]),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => ref.read(navigationServiceProvider).navigateTo('/doctor/profile', arguments: doctor),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage: doctor.imageUrl != null ? NetworkImage(doctor.imageUrl!) : null,
          child: Text(
            doctor.name[0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(doctor.name),
        subtitle: Text(doctor.specialty),
        trailing: doctor.isAvailable
            ? FilledButton(
                onPressed: () => _bookAppointment(doctor),
                child: const Text('Book'),
              )
            : FilledButton.tonal(
                onPressed: null,
                child: const Text('Unavailable'),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Doctors'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  border: OutlineInputBorder(),
                ),
                value: _selectedSpecialty,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Specialties')),
                  ..._specialties.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (value) => setState(() => _selectedSpecialty = value),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available Only'),
                value: _onlyShowAvailable,
                onChanged: (value) => setState(() => _onlyShowAvailable = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sort By',
                  border: OutlineInputBorder(),
                ),
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'availability', child: Text('Availability')),
                ],
                onChanged: (value) => setState(() => _sortBy = value ?? 'name'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Doctor> _filterAndSortDoctors(List<Doctor> doctors) {
    var filtered = doctors.where((doctor) {
      final nameMatch = _searchQuery.isEmpty || doctor.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final specialtyMatch = _selectedSpecialty == null || doctor.specialty == _selectedSpecialty;
      final availabilityMatch = !_onlyShowAvailable || doctor.isAvailable;
      return nameMatch && specialtyMatch && availabilityMatch;
    }).toList();

    switch (_sortBy) {
      case 'availability':
        filtered.sort((a, b) => b.isAvailable ? 1 : -1);
        break;
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }
    return filtered;
  }

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $error', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(doctorNotifierProvider.notifier).refreshDoctors(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No doctors found', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Try adjusting your filters', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );

  void _bookAppointment(Doctor doctor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking appointment with ${doctor.name}'),
        action: SnackBarAction(label: 'Undo', onPressed: () {}),
      ),
    );
  }
}