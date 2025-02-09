import 'package:clinic_appointments/features/patient/view/edit_patient_dialog.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/patient.dart';

class PatientsListView extends StatelessWidget {
  final List<Patient> patients;

  const PatientsListView({super.key, required this.patients});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return Column(
            children: [
              ListTile(
                title: Text(
                  patient.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      patient.phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDateTime(patient.registeredAt),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          patient.notes != null ? ' - ${patient.notes}' : '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditPatientDialog(
                            patient: patient,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () {
                        Provider.of<ClinicService>(context, listen: false)
                            .removePatient(patient.id);
                      },
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
              if (index < patients.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        },
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}  '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
