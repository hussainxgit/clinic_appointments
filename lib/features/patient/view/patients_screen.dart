import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/clinic_service.dart';
import '../../doctor/models/doctor.dart';
import '../models/patient.dart';
import 'add_patient_modal.dart';
import 'patients_grid_view.dart';
import 'search_patient_sheet.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _currentFilter = 'all';
  String? _selectedGender;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedDoctorId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patients',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search patients',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showAdvancedFilterDialog(context),
            tooltip: 'Advanced filters',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (String result) {
              setState(() {
                _currentFilter = result;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'all',
                child: Text('All Patients'),
              ),
              const PopupMenuItem<String>(
                value: 'active',
                child: Text('Active Patients'),
              ),
              const PopupMenuItem<String>(
                value: 'inactive',
                child: Text('Inactive Patients'),
              ),
              const PopupMenuItem<String>(
                value: 'recent',
                child: Text('Recently Added'),
              ),
            ],
            tooltip: 'Filter patients',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (context) => const AddPatientDialog());
        },
        label: const Text('Add Patient'),
        icon: const Icon(Icons.add),
      ),
      body: _buildPatientsList(context),
    );
  }

  Widget _buildPatientsList(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        final allPatients = clinicService.getPatients();
        final filteredPatients = _filterPatients(allPatients, clinicService);

        // Find doctor name if selected
        String? selectedDoctorName;
        if (_selectedDoctorId != null) {
          final doctor = clinicService.getDoctors().firstWhere(
            (d) => d.id == _selectedDoctorId,
            orElse: () => Doctor(
              id: 'unknown', 
              name: 'Unknown Doctor', 
              specialty: '', 
              phoneNumber: '', 
              email: '', 
              isAvailable: false
            ),
          );
          selectedDoctorName = doctor.name;
        }

        if (filteredPatients.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  _currentFilter != 'all' || _hasAdvancedFilters()
                      ? 'No patients match the selected filters'
                      : 'No patients yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _currentFilter != 'all' || _hasAdvancedFilters()
                      ? 'Try changing your filters'
                      : 'Add your first patient to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_currentFilter != 'all' || _hasAdvancedFilters()) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = 'all';
                        _selectedGender = null;
                        _startDate = null;
                        _endDate = null;
                        _selectedDoctorId = null;
                      });
                    },
                    child: const Text('Clear Filters'),
                  ),
                ]
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasActiveFilters()) Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_currentFilter != 'all') _buildFilterChip(_currentFilter),
                  if (_selectedGender != null) _buildFilterChip('Gender: $_selectedGender'),
                  if (_startDate != null) _buildFilterChip('From: ${_startDate!.dateOnly()}'),
                  if (_endDate != null) _buildFilterChip('To: ${_endDate!.dateOnly()}'),
                  if (_selectedDoctorId != null && selectedDoctorName != null) 
                    _buildFilterChip('Doctor: $selectedDoctorName'),
                  if (_hasActiveFilters()) Chip(
                    label: const Text('Clear All'),
                    onDeleted: () {
                      setState(() {
                        _currentFilter = 'all';
                        _selectedGender = null;
                        _startDate = null;
                        _endDate = null;
                        _selectedDoctorId = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Showing ${filteredPatients.length} patients',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: PatientsGridView(patients: filteredPatients),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    String displayLabel = label;
    
    // Format the standard filter labels
    switch (label) {
      case 'all':
        displayLabel = 'All Patients';
        break;
      case 'active':
        displayLabel = 'Active Patients';
        break;
      case 'inactive':
        displayLabel = 'Inactive Patients';
        break;
      case 'recent':
        displayLabel = 'Recently Added';
        break;
    }
    
    return Chip(
      label: Text(displayLabel),
      onDeleted: () {
        setState(() {
          if (label.startsWith('Gender')) {
            _selectedGender = null;
          } else if (label.startsWith('From')) {
            _startDate = null;
          } else if (label.startsWith('To')) {
            _endDate = null;
          } else if (label.startsWith('Doctor')) {
            _selectedDoctorId = null;
          } else {
            _currentFilter = 'all';
          }
        });
      },
    );
  }

  bool _hasAdvancedFilters() {
    return _selectedGender != null || 
           _startDate != null || 
           _endDate != null || 
           _selectedDoctorId != null;
  }

  bool _hasActiveFilters() {
    return _currentFilter != 'all' || _hasAdvancedFilters();
  }

  List<Patient> _filterPatients(List<Patient> patients, ClinicService clinicService) {
    List<Patient> result = List.from(patients);
    
    // Apply status filter
    switch (_currentFilter) {
      case 'active':
        result = result.where((p) => p.status == PatientStatus.active).toList();
        break;
      case 'inactive':
        result = result.where((p) => p.status == PatientStatus.inactive).toList();
        break;
      case 'recent':
        result.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
        result = result.take(10).toList(); // Show 10 most recent
        break;
    }
    
    // Apply gender filter if selected
    if (_selectedGender != null) {
      final gender = _selectedGender == 'Male' 
          ? PatientGender.male 
          : PatientGender.female;
      result = result.where((p) => p.gender == gender).toList();
    }
    
    // Apply date range filter
    if (_startDate != null) {
      result = result.where((p) => 
        p.registeredAt.isAfter(_startDate!) || 
        p.registeredAt.isAtSameMomentAs(_startDate!)
      ).toList();
    }
    
    if (_endDate != null) {
      // Add a day to include the end date fully
      final endDateIncluded = _endDate!.add(const Duration(days: 1));
      result = result.where((p) => p.registeredAt.isBefore(endDateIncluded)).toList();
    }
    
    // Apply doctor filter
    if (_selectedDoctorId != null) {
      // Get all appointments for the selected doctor
      final appointments = clinicService.appointmentProvider.appointments
          .where((a) => a.doctorId == _selectedDoctorId)
          .toList();
      
      // Extract patient IDs who have appointments with this doctor
      final patientIds = appointments.map((a) => a.patientId).toSet();
      
      // Filter patients who have appointments with the selected doctor
      result = result.where((p) => patientIds.contains(p.id)).toList();
    }
    
    return result;
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const SearchPatientSheet(),
    );
  }

  void _showAdvancedFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Advanced Filters'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gender'),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'Male', label: Text('Male')),
                      ButtonSegment<String>(value: 'Female', label: Text('Female')),
                    ],
                    selected: _selectedGender != null ? {_selectedGender!} : {},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _selectedGender = selection.isNotEmpty ? selection.first : null;
                      });
                    },
                    emptySelectionAllowed: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('Registration Date Range'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_startDate != null 
                              ? _startDate!.dateOnly() 
                              : 'Start Date'),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_endDate != null 
                              ? _endDate!.dateOnly()
                              : 'End Date'),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Assigned Doctor'),
                  const SizedBox(height: 8),
                  Consumer<ClinicService>(
                    builder: (context, clinicService, _) {
                      final doctors = clinicService.getDoctors();
                      
                      return DropdownButtonFormField<String>(
                        value: _selectedDoctorId,
                        decoration: const InputDecoration(
                          hintText: 'Select Doctor',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Any Doctor'),
                          ),
                          ...doctors.map((doctor) => DropdownMenuItem<String>(
                            value: doctor.id,
                            child: Text(doctor.name),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDoctorId = value;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGender = null;
                    _startDate = null;
                    _endDate = null;
                    _selectedDoctorId = null;
                  });
                },
                child: const Text('Clear Filters'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Update the main state with the filter values
                  this.setState(() {
                    // The selected values are already updated in the local StatefulBuilder state
                  });
                },
                child: const Text('Apply'),
              ),
            ],
          );
        }
      ),
    );
  }
}