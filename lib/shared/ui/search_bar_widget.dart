import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/features/appointment/models/appointment.dart';
import 'package:clinic_appointments/features/patient/models/patient.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/ui/show_appointment_details_modal.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final SearchController _searchController = SearchController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SearchAnchor(
        builder: (context, controller) {
          return SearchBar(
            elevation: const WidgetStatePropertyAll<double>(0.0),
            controller: controller,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            onTap: () => controller.openView(),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                _searchController.openView();
              });
            },
            leading: const Icon(Icons.search),
            hintText: 'Search appointments by phone number...',
          );
        },
        suggestionsBuilder: (context, controller) {
          final query = controller.text;
          final results = Provider.of<ClinicService>(context, listen: false)
              .searchAppointmentsByPhone(query);

          if (query.isEmpty) {
            return [const ListTile(title: Text('Start typing phone number...'))];
          }
          if (results.isEmpty) {
            return [ListTile(title: Text('No appointments found for "$query"'))];
          }
          return results.map<Widget>((entry) {
            final appointment = entry['appointment'] as Appointment;
            final patient = entry['patient'] as Patient;
            return ListTile(
              title: Text(patient.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.phone),
                  Text('Date: ${appointment.dateTime.dateOnly()}'),
                  Text('Status: ${appointment.status.toUpperCase()}'),
                ],
              ),
              onTap: () {
                controller.closeView(patient.phone);
                showAppointmentDetailsModal(context, {
                  'appointment': appointment,
                  'patient': patient,
                });
              },
            );
          }).toList();
        },
      ),
    );
  }
}