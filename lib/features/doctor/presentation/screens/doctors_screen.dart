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
        elevation: 0,
        title: const Text('All Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildDoctorList(doctorState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigationService.navigateTo('/doctor/add'),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search doctors...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
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
      onRefresh:
          () => ref.read(doctorNotifierProvider.notifier).refreshDoctors(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredDoctors.length,
        itemBuilder:
            (context, index) => _buildDoctorCard(filteredDoctors[index]),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return ListTile(
      onTap:
          () => ref
              .read(navigationServiceProvider)
              .navigateTo('/doctor/profile', arguments: doctor),
      contentPadding: const EdgeInsets.all(16),
      // Leading widget (Avatar with availability indicator)
      leading: SizedBox(
        width: 60, // Fixed width to maintain consistent layout
        child: Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              foregroundImage:
                  doctor.imageUrl != null
                      ? NetworkImage(doctor.imageUrl!)
                      : null,
              child: Text(
                doctor.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (doctor.isAvailable)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      // Title and subtitle
      title: Text(
        doctor.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          doctor.specialty,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ),
      trailing: OutlinedButton(
        onPressed: () {
          _bookAppointment(doctor);
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: const Text('Book Appointment'),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Doctors',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Specialty',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedSpecialty,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Specialties'),
                          ),
                          ..._specialties.map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(
                            () => setState(() => _selectedSpecialty = value),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Show Available Only'),
                        value: _onlyShowAvailable,
                        onChanged: (value) {
                          setModalState(
                            () => setState(() => _onlyShowAvailable = value),
                          );
                        },
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
                          DropdownMenuItem(
                            value: 'availability',
                            child: Text('Availability'),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(
                            () => setState(() => _sortBy = value ?? 'name'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  List<Doctor> _filterAndSortDoctors(List<Doctor> doctors) {
    var filtered =
        doctors.where((doctor) {
          final nameMatch =
              _searchQuery.isEmpty ||
              doctor.name.toLowerCase().contains(_searchQuery.toLowerCase());
          final specialtyMatch =
              _selectedSpecialty == null ||
              doctor.specialty == _selectedSpecialty;
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
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text('Error: $error', style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed:
              () => ref.read(doctorNotifierProvider.notifier).refreshDoctors(),
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'No doctors found',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          'Try adjusting your filters',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
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
