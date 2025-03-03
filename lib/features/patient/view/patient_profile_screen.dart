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
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile tapped!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildPatientSummary(context),
            Expanded(
              child: _buildTabSection(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSummary(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPatientAvatar(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.name,
                            style: theme.textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(context, 'Active'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPatientInfo(context, 'ID: ${patient.id}'),
                    const SizedBox(height: 4),
                    _buildPatientInfo(context, 'Phone: ${patient.phone}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Hero(
      tag: 'patient-${patient.id}',
      child: CircleAvatar(
        radius: 40,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: Text(
          patient.name[0].capitalize(),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isActive = status.toLowerCase() == 'active';
    final backgroundColor = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final textColor = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPatientInfo(BuildContext context, String info) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          info,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabSection(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: _buildTabBarView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: TabBar(
        isScrollable: true,
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Appointments'),
          Tab(text: 'Medical Records'),
        ],
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 3,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildTabBarView(BuildContext context) {
    return TabBarView(
      children: [
        DetailsTab(patient: patient),
        AppointmentsTab(patient: patient),
        MedicalRecordsTab(patient: patient),
      ],
    );
  }
}

class DetailsTab extends StatelessWidget {
  final Patient patient;

  const DetailsTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPersonalInfoSection(context),
        const SizedBox(height: 24),
        _buildMedicalInfoSection(context),
        const SizedBox(height: 24),
        _buildEmergencyContactSection(context),
      ],
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context) {
    return _buildInfoSection(
      context,
      title: 'Personal Information',
      leadingIcon: Icons.person_outline,
      items: [
        InfoItem(label: 'Full Name', value: patient.name),
        InfoItem(label: 'Gender', value: 'Male'),
        InfoItem(label: 'Date of Birth', value: '30/06/1996'),
        InfoItem(label: 'Age', value: '32Y 2M'),
        InfoItem(label: 'Address', value: '123 Main Street'),
        InfoItem(label: 'Email', value: 'henry@example.com'),
        InfoItem(label: 'Phone', value: patient.phone),
      ],
    );
  }

  Widget _buildMedicalInfoSection(BuildContext context) {
    return _buildInfoSection(
      context,
      title: 'Medical Information',
      leadingIcon: Icons.medical_information_outlined,
      items: [
        InfoItem(label: 'Primary Physician', value: 'Dr. Emily Davies'),
        InfoItem(label: 'Blood Type', value: 'O+'),
        InfoItem(label: 'Allergies', value: 'Penicillin'),
        InfoItem(
          label: 'Chronic Conditions',
          value: 'Hypertension (Diagnosed: 01/10/2022)',
        ),
        InfoItem(label: 'Medication', value: 'Atenolol 50mg'),
        InfoItem(label: 'Surgeries', value: 'Appendectomy (2020)'),
      ],
    );
  }

  Widget _buildEmergencyContactSection(BuildContext context) {
    return _buildInfoSection(
      context,
      title: 'Emergency Contact',
      leadingIcon: Icons.contact_phone_outlined,
      items: [
        InfoItem(label: 'Name', value: 'Mary Smith'),
        InfoItem(label: 'Relationship', value: 'Spouse'),
        InfoItem(label: 'Phone', value: '+123 456 7891'),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context, {
    required String title,
    required IconData leadingIcon,
    required List<InfoItem> items,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  leadingIcon,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24.0,
              runSpacing: 16.0,
              children: items,
            ),
          ],
        ),
      ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const InfoItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentsTab extends StatelessWidget {
  final Patient patient;

  const AppointmentsTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: PatientAppointmentList(patient: patient),
    );
  }
}

class MedicalRecordsTab extends StatelessWidget {
  final Patient patient;

  const MedicalRecordsTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_information_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Medical Records',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'All patient medical history and documents.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add Medical Record'),
          ),
        ],
      ),
    );
  }
}
