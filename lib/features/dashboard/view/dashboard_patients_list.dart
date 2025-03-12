import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/features/patient/models/patient.dart';
import 'package:clinic_appointments/features/patient/view/patient_profile_screen.dart';
import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import '../../patient/view/add_patient_modal.dart';
import 'dashboard_empty_state.dart';

class DashboardPatientsList extends StatelessWidget {
  const DashboardPatientsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        final patients = clinicService.getPatients();
        if (patients.isEmpty) {
          return DashboardEmptyState(
            message: 'No patients found',
            icon: Icons.people_alt_outlined,
            buttonText: 'Add Patient',
            onButtonPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddPatientDialog(),
              );
            },
          );
        }

        final isSmall = context.isSmallScreen;

        return ListView.separated(
          itemCount: patients.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final patient = patients[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Colors.primaries[index % Colors.primaries.length],
                child: Text(patient.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white)),
              ),
              title: Text(
                patient.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 16),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(patient.phone, overflow: TextOverflow.ellipsis),
              trailing: isSmall
                  ? Icon(
                      patient.status == PatientStatus.active
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: patient.status == PatientStatus.active
                          ? Colors.green
                          : Colors.red,
                    )
                  : Text(
                      patient.status == PatientStatus.active
                          ? 'Active'
                          : 'Inactive',
                      style: TextStyle(
                        color: patient.status == PatientStatus.active
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        PatientProfileScreen(patient: patient),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}