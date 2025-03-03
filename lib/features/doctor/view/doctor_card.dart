// Reusable widget for a single doctor's card
import 'package:clinic_appointments/features/doctor/view/doctor_profile_screen.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import 'doctor_avatar.dart';

class DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final int index;

  const DoctorCard({
    super.key,
    required this.doctor,
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
            builder: (context) => DoctorProfileScreen(doctor: doctor),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildDoctorInfo(theme, colorScheme),
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
        DoctorAvatar(
          imageUrl: doctor.imageUrl,
          name: doctor.name,
          index: index,
          radius: 48,
        ),
        _buildActionMenu(context),
      ],
    );
  }

  Widget _buildDoctorInfo(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          doctor.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          doctor.specialty,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              '4.8',
              style: theme.textTheme.bodySmall,
            ),
          ],
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
              icon: Icon(Icons.message, color: colorScheme.primary),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
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
          icon: const Icon(Icons.more_vert),
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
          leadingIcon: const Icon(Icons.calendar_today, color: Colors.green),
          child: const Text('View schedule'),
          onPressed: () {},
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete, color: Colors.red),
          child: const Text('Delete doctor'),
          onPressed: () {
            Provider.of<ClinicService>(context, listen: false)
                .deleteDoctor(doctor.id);
          },
        ),
      ],
    );
  }
}
