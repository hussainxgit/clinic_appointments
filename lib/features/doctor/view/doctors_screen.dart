import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/clinic_service.dart';
import 'search_doctor_sheet.dart';
import 'doctors_grid_view.dart';
import 'filter_doctors_sheet.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  // Filter state
  bool _showOnlyAvailable = false;
  String? _selectedSpecialty;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctors',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSheet(context),
            tooltip: 'Search doctors',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter doctors',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new doctor functionality
        },
        tooltip: 'Add doctor',
        child: const Icon(Icons.add),
      ),
      body: _buildDoctorsList(context),
    );
  }

  Widget _buildDoctorsList(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        final allDoctors = clinicService.getDoctors();
        
        // Apply filters
        final doctors = allDoctors.where((doctor) {
          // Availability filter
          if (_showOnlyAvailable && !doctor.isAvailable) {
            return false;
          }
          
          // Specialty filter
          if (_selectedSpecialty != null && 
              _selectedSpecialty!.isNotEmpty && 
              doctor.specialty != _selectedSpecialty) {
            return false;
          }
          
          return true;
        }).toList();
        
        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No doctors found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_showOnlyAvailable || _selectedSpecialty != null)
                  ElevatedButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  )
                else
                  Text(
                    'Add doctors to your clinic',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showOnlyAvailable || _selectedSpecialty != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_showOnlyAvailable)
                      _buildFilterChip(
                        'Available Only', 
                        () => _setAvailabilityFilter(false)
                      ),
                    if (_selectedSpecialty != null)
                      _buildFilterChip(
                        'Specialty: $_selectedSpecialty', 
                        () => _setSpecialtyFilter(null)
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DoctorsGridView(doctors: doctors),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const SearchDoctorSheet(),
    );
  }
  
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterDoctorsSheet(
        showOnlyAvailable: _showOnlyAvailable,
        selectedSpecialty: _selectedSpecialty,
        onApplyFilters: (showOnlyAvailable, specialty) {
          setState(() {
            _showOnlyAvailable = showOnlyAvailable;
            _selectedSpecialty = specialty;
          });
        },
      ),
    );
  }
  
  void _setAvailabilityFilter(bool value) {
    setState(() {
      _showOnlyAvailable = value;
    });
  }
  
  void _setSpecialtyFilter(String? value) {
    setState(() {
      _selectedSpecialty = value;
    });
  }
  
  void _clearFilters() {
    setState(() {
      _showOnlyAvailable = false;
      _selectedSpecialty = null;
    });
  }
}