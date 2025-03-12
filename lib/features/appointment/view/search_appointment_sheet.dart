import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../patient/models/patient.dart';
import '../models/appointment.dart';

class SearchAppointmentSheet extends StatefulWidget {
  final Function(Appointment)? onAppointmentSelected;

  const SearchAppointmentSheet({
    super.key,
    this.onAppointmentSelected,
  });

  @override
  State<SearchAppointmentSheet> createState() => _SearchAppointmentSheetState();
}

class _SearchAppointmentSheetState extends State<SearchAppointmentSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
              'Search Appointments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SearchBar(
            controller: _searchController,
            hintText: 'Appointment name, ID, or phone',
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
    final appointmentProvider = Provider.of<ClinicService>(context);
    List<Map<String, dynamic>> searchResults = appointmentProvider.searchAppointmentsByQuery(_searchQuery);

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
                    child: Text('No Appointments found'),
                  )
                : ListView.builder(
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final appointment = searchResults[index]['appointment'];
                      final patient = searchResults[index]['patient'];
                      return AppointmentListItem(
                        patient: patient,
                        appointment: appointment,
                        onTap: () {
                          if (widget.onAppointmentSelected != null) {
                            widget.onAppointmentSelected!(appointment);
                          }
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

}

class AppointmentListItem extends StatelessWidget {
  final Patient patient;
  final Appointment appointment;
  final VoidCallback onTap;

  const AppointmentListItem({
    super.key,
    required this.appointment,
    required this.onTap,
    required this.patient,
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
