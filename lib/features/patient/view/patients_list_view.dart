import 'package:clinic_appointments/features/patient/view/edit_patient_dialog.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';
import 'patient_screen.dart';

class PatientsListView extends StatelessWidget {
  final List<Patient> patients;

  const PatientsListView({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: patients.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          itemBuilder: (context, index) {
            final patient = patients[index];
            return ListTile(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PatientProfileScreen(patient: patient,)));
              },
              leading: CircleAvatar(
                backgroundColor: _getAvatarColor(index),
                child: Text(
                  patient.name[0].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              title: Text(
                patient.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registered at: ${patient.registeredAt.dateOnly()}${patient.notes != null ? ' - ${patient.notes}' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            EditPatientDialog(patient: patient),
                      );
                    },
                    icon: Icon(Icons.edit_outlined, size: 24),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () {
                      Provider.of<ClinicService>(context, listen: false)
                          .removePatient(patient.id);
                    },
                    icon: Icon(Icons.delete_outline, size: 24),
                    color: Theme.of(context).colorScheme.error,
                    tooltip: 'Delete',
                  ),
                ],
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            );
          },
        ),
      ),
    );
  }

  Color _getAvatarColor(int index) {
    const List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length]; // Deterministic color assignment
  }
}
