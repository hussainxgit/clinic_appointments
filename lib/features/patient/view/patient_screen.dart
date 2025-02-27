import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';

import '../models/patient.dart';
import 'patient_appointment_list.dart';

class PatientProfileScreen extends StatelessWidget {
  final Patient patient;
  const PatientProfileScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0, // No shadow for a flat look in M3
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Add edit action (e.g., navigate to edit screen)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit profile tapped!')),
              );
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPatientHeader(context),
            const SizedBox(height: 24), // Increased spacing for M3 hierarchy
            _buildTabSection(context),
          ],
        ),
      ),
    );
  }

  // Patient header with M3 design and UX improvements
  Widget _buildPatientHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            patient.name[0].capitalize(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ), // Replace with actual image path
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: TextStyle(
                      fontSize: 24, // Larger for M3 emphasis
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius:
                          BorderRadius.circular(8), // Rounded corners for M3
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${patient.id}  | Phone:  ${patient.phone}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Tab section with M3 design and UX improvements
  Widget _buildTabSection(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs (note: design suggests 6, including "Chat")
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'Details'),
              Tab(text: 'Appointments'),
              Tab(text: 'Etc'),
            ],
            tabAlignment: TabAlignment.start,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            labelStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 16),
            labelPadding: const EdgeInsets.symmetric(
                horizontal: 12.0), // Adjusts padding to fit text
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 500, // Adjust height or use Flexible for dynamic sizing
            child: TabBarView(
              children: [
                const DetailsTabContent(),
                AppointmentsTab(
                  patient: patient,
                ),
                const EtcTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Details Tab Content with M3 and UX improvements
class DetailsTabContent extends StatelessWidget {
  const DetailsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSection(context, title: 'Personal Information', items: [
          _InfoItem(label: 'Name', value: 'Henry'),
          _InfoItem(label: 'Gender', value: 'Male'),
          _InfoItem(label: 'Address', value: '123 Main Street'),
          _InfoItem(label: 'Email', value: 'henny@gmail.com'),
          _InfoItem(label: 'Phone', value: '+123 456 7890'),
          _InfoItem(label: 'DOB', value: '30/06/1996'),
          _InfoItem(label: 'Age', value: '32Y 2M'),
        ]),
        _buildSection(context,
            title: 'Medical Information', items: _buildMedicalInfo(context)),
      ],
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: items,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Updated _buildMedicalInfo to return a List<Widget> for Wrap
  List<Widget> _buildMedicalInfo(BuildContext context) {
    return [
      _InfoItem(label: 'Primary Physician', value: 'Dr. Emily Davies'),
      _InfoItem(label: 'Allergies', value: 'Penicillin'),
      _InfoItem(
          label: 'Chronic Conditions',
          value: 'Hypertension (Diagnosed: 01/10/2022)'),
      _InfoItem(label: 'Medication', value: 'Atenolol 50mg'),
      _InfoItem(label: 'Surgeries', value: 'Appendectomy (2020)'),
    ];
  }
}

// Reusable Info Item Widget (unchanged)
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, // Fixed width for consistent layout
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

// Placeholder for Appointments Tab with M3 and UX improvements
class AppointmentsTab extends StatelessWidget {
  final Patient patient;
  const AppointmentsTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: PatientAppointmentList(
        patient: patient,
      ),
    );
  }
}

// Placeholder for Etc Tab with M3 and UX improvements
class EtcTab extends StatelessWidget {
  const EtcTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Etc (10)',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'View or add patient Etc here.',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

