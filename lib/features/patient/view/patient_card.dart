// Reusable widget for a single Patient's card
import 'package:clinic_appointments/features/patient/view/patient_profile_screen.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/clinic_service.dart';
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
        if (patient.dateOfBirth != null)
          Text(
            'DOB: ${patient.dateOfBirth!.dateOnly()}',
            style: theme.textTheme.bodyMedium,
          ),
        if (patient.id.isNotEmpty)
          Text(
            'ID: ${patient.id}',
            style: theme.textTheme.bodySmall,
          ),
        if (patient.phone.isNotEmpty)
          Text(
            'Phone: ${patient.phone}',
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
          'Send SMS',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
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
        if (patient.status == PatientStatus.inactive)
          MenuItemButton(
            leadingIcon: Icon(Icons.check_circle, color: Colors.green),
            child: Text('Activate patient'),
            onPressed: () {
              Provider.of<ClinicService>(context, listen: false)
                  .activatePatient(patient.id);
            },
          ),
        if (patient.status == PatientStatus.active)
          MenuItemButton(
            leadingIcon: Icon(Icons.pause_circle, color: Colors.yellow),
            child: Text('Suspend patient'),
            onPressed: () {
              Provider.of<ClinicService>(context, listen: false)
                  .suspendPatient(patient.id);
            },
          ),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete, color: Colors.red),
          child: Text('Delete patient'),
          onPressed: () {
            showConfirmationDialog(
                context: context,
                title: 'Delete Patient',
                message: 'Are you sure you want to delete this patient?',
                onConfirm: () {
                  Provider.of<ClinicService>(context, listen: false)
                      .removePatientWithCascade(patient.id);
                });
          },
        ),
      ],
    );
  }

  void showConfirmationDialog(
      {required BuildContext context,
      required String title,
      required String message,
      required Null Function() onConfirm}) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  onConfirm();
                  Navigator.of(context).pop();
                },
                child: Text('Confirm'),
              ),
            ],
          );
        });
  }
}
