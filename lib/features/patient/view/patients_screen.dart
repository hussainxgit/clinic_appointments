import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/provider/clinic_service.dart';
import 'patients_grid_view.dart';
import 'search_patient_sheet.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patients',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search patients',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {},
            tooltip: 'Filter patients',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new patient
        },
        child: Icon(Icons.add),
      ),
      body: _buildPatientsList(context),
    );
  }

  Widget _buildPatientsList(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        final patients = clinicService.getPatients();

        if (patients.isEmpty) {
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
                  'No patients yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first patient to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: PatientsGridView(patients: patients),
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SearchPatientSheet(),
    );
  }
}
