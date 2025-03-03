import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import 'patient_profile_screen.dart';

class SearchPatientSheet extends StatefulWidget {
  final Function(Patient)? onPatientSelected;

  const SearchPatientSheet({
    super.key,
    this.onPatientSelected,
  });

  @override
  State<SearchPatientSheet> createState() => _SearchPatientSheetState();
}

class _SearchPatientSheetState extends State<SearchPatientSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Patient> _recentSearches = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Search Patients',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SearchBar(
            controller: _searchController,
            hintText: 'Patient name, ID, or phone',
            leading: const Icon(Icons.search),
            trailing: [
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16.0)),
          ),
          const SizedBox(height: 16),
          _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final patientProvider = Provider.of<ClinicService>(context);
    List<Patient> searchResults = [];

    if (_searchQuery.isNotEmpty) {
      // Search by name, ID, or phone
      searchResults = patientProvider.searchPatientByQuery(_searchQuery);

      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Results',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: searchResults.isEmpty
                  ? const Center(
                      child: Text('No patients found'),
                    )
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final patient = searchResults[index];
                        return PatientListItem(
                          patient: patient,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PatientProfileScreen(patient: patient),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _recentSearches.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent searches'),
                )
              : Column(
                  children: _recentSearches.map((patient) {
                    return PatientListItem(
                      patient: patient,
                      onTap: () {
                        if (widget.onPatientSelected != null) {
                          widget.onPatientSelected!(patient);
                        }
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
        ],
      );
    }
  }
}

class PatientListItem extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;

  const PatientListItem({
    super.key,
    required this.patient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(patient.name[0].toUpperCase()),
      ),
      title: Text(patient.name),
      subtitle: Text('Phone: ${patient.phone}'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
