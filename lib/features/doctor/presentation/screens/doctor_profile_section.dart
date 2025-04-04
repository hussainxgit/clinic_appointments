import 'package:flutter/material.dart';
import '../../../../core/ui/theme/app_theme.dart';
import '../../../../core/ui/theme/app_colors.dart';
import '../../domain/entities/doctor.dart';

class DoctorProfileSection extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onViewAppointments;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final Function(bool) onToggleAvailability;

  const DoctorProfileSection({
    super.key,
    required this.doctor,
    required this.onViewAppointments,
    required this.onCall,
    required this.onMessage,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      color: Colors.grey[50],
      child: Stack(
        children: [
          // Header with gradient background
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.7),
                  AppTheme.primaryColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content with curved top
          Column(
            children: [
              // Doctor profile header
              _ProfileHeader(doctor: doctor),

              // Action buttons
              _ActionButtons(
                onAppointments: onViewAppointments,
                onCall: onCall,
                onMessage: onMessage,
              ),

              // Content in scrollview
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AvailabilityCard(
                          doctor: doctor,
                          onToggleAvailability: onToggleAvailability,
                        ),
                        const SizedBox(height: 16),
                        _ContactInfoCard(doctor: doctor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Doctor doctor;

  const _ProfileHeader({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              foregroundImage:
                  doctor.imageUrl != null
                      ? NetworkImage(doctor.imageUrl!)
                      : null,
              child:
                  doctor.imageUrl == null
                      ? Text(
                        doctor.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40,
                          color: AppTheme.primaryColor,
                        ),
                      )
                      : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Dr. ${doctor.name}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              doctor.specialty,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onAppointments;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const _ActionButtons({
    required this.onAppointments,
    required this.onCall,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.assignment,
            label: 'Appointments',
            onPressed: onAppointments,
          ),
          _ActionButton(icon: Icons.phone, label: 'Call', onPressed: onCall),
          _ActionButton(
            icon: Icons.message,
            label: 'Message',
            onPressed: onMessage,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppTheme.primaryColor, size: 16),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final Doctor doctor;
  final Function(bool) onToggleAvailability;

  const _AvailabilityCard({
    required this.doctor,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Availability',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                _StatusBadge(isAvailable: doctor.isAvailable),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  doctor.isAvailable
                      ? 'Accepting appointments'
                      : 'Not available for appointments',
                  style: TextStyle(
                    color:
                        doctor.isAvailable
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                  ),
                ),
                Switch(
                  value: doctor.isAvailable,
                  onChanged: onToggleAvailability,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isAvailable;

  const _StatusBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            isAvailable
                ? AppTheme.successColor.withOpacity(0.2)
                : AppTheme.errorColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: TextStyle(
          color: isAvailable ? AppTheme.successColor : AppTheme.errorColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  final Doctor doctor;

  const _ContactInfoCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade50,
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          'Contact Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: doctor.phoneNumber,
                ),
                if (doctor.email != null)
                  _InfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: doctor.email!,
                  ),
                if (doctor.bio != null && doctor.bio!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(doctor.bio!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}
