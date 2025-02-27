import 'package:flutter/material.dart';
import '../models/doctor.dart';

class DoctorsListView extends StatelessWidget {
  final List<Doctor> doctors;

  const DoctorsListView({super.key, required this.doctors});

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
          physics: const NeverScrollableScrollPhysics(),
          itemCount: doctors.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getAvatarColor(index),
                child: Text(
                  doctor.name[0].toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              title: Text(
                doctor.name,
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
                      doctor.phoneNumber,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${doctor.specialty}${doctor.email != null ? ' - ${doctor.email}' : ''}',
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
                      // TODO: Implement Edit Doctor Dialog
                      // showDialog(
                      //   context: context,
                      //   builder: (context) => EditDoctorDialog(doctor: doctor),
                      // );
                    },
                    icon: Icon(Icons.edit_outlined, size: 24),
                    color: Theme.of(context).colorScheme.primary,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement Doctor Removal via ClinicService
                      // Provider.of<ClinicService>(context, listen: false)
                      //     .removeDoctor(doctor.id);
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
