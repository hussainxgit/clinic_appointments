// Reusable widget for a single Patient's card
import 'package:clinic_appointments/features/patient/view/patient_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/provider/clinic_service.dart';
import '../models/patient.dart';
import 'patient_avatar.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final int index;

  const PatientCard({
    super.key,
    required this.patient,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientProfileScreen(patient: patient),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildPatientInfo(theme),
              const Spacer(),
              _buildContactActions(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PatientAvatar(
          imageUrl: '',
          name: patient.name,
          index: index,
          radius: 48,
        ),
        _buildActionMenu(context),
      ],
    );
  }

  Widget _buildPatientInfo(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          patient.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // if (patient.dateOfBirth != null)
        //   Text(
        //     'DOB: ${_formatDate(patient.dateOfBirth!)}',
        //     style: theme.textTheme.bodyMedium,
        //   ),
        if (patient.id.isNotEmpty)
          Text(
            'ID: ${patient.id}',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildContactActions(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Contact',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.phone, color: colorScheme.primary),
              style: IconButton.styleFrom(
                minimumSize: Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.message, color: colorScheme.primary),
              style: IconButton.styleFrom(
                minimumSize: Size(40, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(Icons.stop_circle_rounded, color: Colors.red),
          child: Text('Suspend patient'),
          onPressed: () {},
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete, color: Colors.red),
          child: Text('Delete patient'),
          onPressed: () {
            Provider.of<ClinicService>(context, listen: false)
                .removePatient(patient.id);
          },
        ),
      ],
    );
  }
}
