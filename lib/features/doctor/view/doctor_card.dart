import 'package:clinic_appointments/features/doctor/view/doctor_appointments_screen.dart';
import 'package:clinic_appointments/features/doctor/view/doctor_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/clinic_service.dart';
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
    
    // Get screen dimensions
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTablet = size.width < 1100 && size.width >= 600;
    final isIpadLandscape = isTablet && isLandscape;
    
    // Adjust padding based on screen size
    final padding = isIpadLandscape ? 10.0 : 16.0;
    
    // Adjust spacing
    final verticalSpacing = isIpadLandscape ? 8.0 : 16.0;
    final smallSpacing = isIpadLandscape ? 2.0 : 4.0;
    
    // Adjust avatar size
    final avatarRadius = isIpadLandscape ? 36.0 : 48.0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.hardEdge,
      color: colorScheme.surfaceContainerLow,
      margin: EdgeInsets.all(isIpadLandscape ? 4.0 : 8.0),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DoctorProfileScreen(doctor: doctor),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, avatarRadius),
              SizedBox(height: verticalSpacing),
              _buildDoctorInfo(context, theme, colorScheme, smallSpacing),
              const Spacer(),
              _buildContactActions(colorScheme, isIpadLandscape),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double avatarRadius) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DoctorAvatar(
          imageUrl: doctor.imageUrl,
          name: doctor.name,
          index: index,
          radius: avatarRadius,
        ),
        _buildActionMenu(context),
      ],
    );
  }

  Widget _buildDoctorInfo(context, ThemeData theme, ColorScheme colorScheme, double spacing) {
    // Get screen dimensions
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;  // Default for safety
    final isTablet = size.width < 1100 && size.width >= 600;
    final isIpadLandscape = isTablet && isLandscape;
    
    // Adjust text sizes
    final nameStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: isIpadLandscape ? 14 : null,
    );
    
    final specialtyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontSize: isIpadLandscape ? 12 : null,
    );
    
    final ratingStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: isIpadLandscape ? 10 : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          doctor.name,
          style: nameStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: spacing),
        Text(
          doctor.specialty,
          style: specialtyStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Icon(
              Icons.star,
              size: isIpadLandscape ? 14 : 16,
              color: Colors.amber,
            ),
            SizedBox(width: spacing / 2),
            Text(
              '4.8',
              style: ratingStyle,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactActions(ColorScheme colorScheme, bool isIpadLandscape) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Contact',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
            fontSize: isIpadLandscape ? 12 : 14,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.message, 
                color: colorScheme.primary,
                size: isIpadLandscape ? 20 : 24,
              ),
              style: IconButton.styleFrom(
                minimumSize: Size(isIpadLandscape ? 32 : 40, isIpadLandscape ? 32 : 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionMenu(BuildContext context) {
    // Get screen dimensions for icon size
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    final isTablet = size.width < 1100 && size.width >= 600;
    final isIpadLandscape = isTablet && isLandscape;
    
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          icon: Icon(Icons.more_vert, 
            size: isIpadLandscape ? 20 : 24,
          ),
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
          child: Text('View schedule', 
            style: TextStyle(fontSize: isIpadLandscape ? 13 : 14),
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DoctorAppointmentsScreen(doctorId: doctor.id),
              ),
            );
          },
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete, color: Colors.red),
          child: Text('Delete doctor',
            style: TextStyle(fontSize: isIpadLandscape ? 13 : 14),
          ),
          onPressed: () {
            Provider.of<ClinicService>(context, listen: false)
                .deleteDoctor(doctor.id);
          },
        ),
      ],
    );
  }
}