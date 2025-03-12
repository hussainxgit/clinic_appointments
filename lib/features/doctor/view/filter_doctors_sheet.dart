import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/clinic_service.dart';

class FilterDoctorsSheet extends StatefulWidget {
  final bool showOnlyAvailable;
  final String? selectedSpecialty;
  final Function(bool showOnlyAvailable, String? specialty) onApplyFilters;

  const FilterDoctorsSheet({
    super.key,
    required this.showOnlyAvailable,
    required this.selectedSpecialty,
    required this.onApplyFilters,
  });

  @override
  State<FilterDoctorsSheet> createState() => _FilterDoctorsSheetState();
}

class _FilterDoctorsSheetState extends State<FilterDoctorsSheet> {
  late bool _showOnlyAvailable;
  String? _selectedSpecialty;
  List<String> _availableSpecialties = [];

  @override
  void initState() {
    super.initState();
    _showOnlyAvailable = widget.showOnlyAvailable;
    _selectedSpecialty = widget.selectedSpecialty;
    _loadSpecialties();
  }

  void _loadSpecialties() {
    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final doctors = clinicService.getDoctors();
    
    // Extract unique specialties
    final specialties = doctors
        .map((doctor) => doctor.specialty)
        .toSet()
        .toList();
    
    setState(() {
      _availableSpecialties = specialties;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Filter Doctors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Availability filter
          SwitchListTile(
            title: const Text('Show only available doctors'),
            value: _showOnlyAvailable,
            onChanged: (value) {
              setState(() {
                _showOnlyAvailable = value;
              });
            },
          ),
          
          const Divider(),
          
          // Specialty filter
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Specialty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedSpecialty == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSpecialty = null;
                    });
                  }
                },
              ),
              ..._availableSpecialties.map((specialty) {
                return FilterChip(
                  label: Text(specialty),
                  selected: _selectedSpecialty == specialty,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSpecialty = selected ? specialty : null;
                    });
                  },
                );
              }),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_showOnlyAvailable, _selectedSpecialty);
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}