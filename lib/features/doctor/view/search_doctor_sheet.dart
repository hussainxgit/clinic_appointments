import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import 'doctor_profile_screen.dart';

class SearchDoctorSheet extends StatefulWidget {
  final Function(Doctor)? onDoctorSelected;

  const SearchDoctorSheet({
    super.key,
    this.onDoctorSelected,
  });

  @override
  State<SearchDoctorSheet> createState() => _SearchDoctorSheetState();
}

class _SearchDoctorSheetState extends State<SearchDoctorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<Doctor> _recentSearches = [];

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
              'Search Doctors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SearchBar(
            controller: _searchController,
            hintText: 'Doctor name, ID, or phone',
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
    final doctorProvider = Provider.of<ClinicService>(context);
    List<Doctor> searchResults = [];

    if (_searchQuery.isNotEmpty) {
      // Search by name, ID, or phone
      searchResults = doctorProvider.searchDoctorByQuery(_searchQuery);

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
                      child: Text('No Doctors found'),
                    )
                  : ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final doctor = searchResults[index];
                        return DoctorListItem(
                            doctor: doctor,
                            onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DoctorProfileScreen(doctor: doctor),
                                  ),
                                ));
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
                  children: _recentSearches.map((doctor) {
                    return DoctorListItem(
                      doctor: doctor,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              DoctorProfileScreen(doctor: doctor),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      );
    }
  }
}

class DoctorListItem extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;

  const DoctorListItem({
    super.key,
    required this.doctor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(doctor.name[0].toUpperCase()),
      ),
      title: Text(doctor.name),
      subtitle: Text('Phone: ${doctor.phoneNumber}'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
