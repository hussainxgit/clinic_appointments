// doctors_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Import intl

import '../../../../core/di/core_providers.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/ui/theme/app_colors.dart';
import '../../domain/entities/doctor.dart';
import '../../presentation/provider/doctor_notifier.dart';

// --- Main Screen Widget ---

class DoctorsScreen extends ConsumerStatefulWidget {
  const DoctorsScreen({super.key});

  @override
  ConsumerState<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends ConsumerState<DoctorsScreen> {
  // Keep search query state local to the screen
  String _searchQuery = '';

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctors = ref.watch(
      doctorNotifierProvider.select((state) => state.doctors),
    );
    final isLoading = ref.watch(
      doctorNotifierProvider.select((state) => state.isLoading),
    );
    final error = ref.watch(
      doctorNotifierProvider.select((state) => state.error),
    );

    final navigationService = ref.read(navigationServiceProvider);

    // Filter doctors based on the search query
    final filteredDoctors =
        doctors
            .where(
              (doctor) =>
                  _searchQuery.isEmpty ||
                  doctor.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList();

    return Scaffold(
      // Use the extracted AppBar widget
      appBar: DoctorsAppBar(
        doctorCount: filteredDoctors.length, // Show count of filtered doctors
        onAddDoctorPressed: () => navigationService.navigateTo('/doctor/add'),
      ),
      body: Container(
        color: Colors.grey[50], // Background color for the body
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Use the extracted Search Bar widget
              DoctorSearchBar(onChanged: _onSearchChanged),
              const SizedBox(height: 16),
              // Handle loading, error, and data states
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                        // Use the extracted Error View widget
                        ? ErrorView(
                          error: error,
                          onRetry:
                              () =>
                                  ref
                                      .read(doctorNotifierProvider.notifier)
                                      .refreshDoctors(),
                        )
                        : filteredDoctors.isEmpty
                        ? const Center(child: Text('No doctors found.'))
                        // Use the extracted Grid View widget
                        : DoctorGridView(doctors: filteredDoctors),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Extracted Widgets ---

// AppBar Widget
class DoctorsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int doctorCount;
  final VoidCallback onAddDoctorPressed;

  const DoctorsAppBar({
    super.key,
    required this.doctorCount,
    required this.onAddDoctorPressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      title: Row(
        children: [
          Text(
            doctorCount.toString(),
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Doctors',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: onAddDoctorPressed,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Doctor',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
      backgroundColor: Colors.white,
      elevation: 0,
      // Setting elevation to 0 might remove the default bottom border.
      // Add a border manually if desired.
      // bottom: PreferredSize(
      //   preferredSize: const Size.fromHeight(1.0),
      //   child: Container(
      //     color: Colors.grey[300],
      //     height: 1.0,
      //   ),
      // ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// Search Bar Widget
class DoctorSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const DoctorSearchBar({super.key, required this.onChanged});

  @override
  State<DoctorSearchBar> createState() => _DoctorSearchBarState();
}

class _DoctorSearchBarState extends State<DoctorSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Search doctors by name...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon:
            _controller.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged(
                      '',
                    ); // Notify parent that search is cleared
                  },
                )
                : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
    );
  }
}

// Grid View Widget
class DoctorGridView extends StatelessWidget {
  final List<Doctor> doctors;

  const DoctorGridView({super.key, required this.doctors});

  @override
  Widget build(BuildContext context) {
    // Consider making these constants or configurable
    const crossAxisCount = 4;
    const aspectRatio = 0.85; // Adjust as needed for content
    const spacing = 12.0;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        // Use the extracted Doctor Card widget
        return DoctorCard(doctor: doctors[index]);
      },
    );
  }
}

// Doctor Card Widget
class DoctorCard extends ConsumerWidget {
  final Doctor doctor;

  const DoctorCard({super.key, required this.doctor});

  // Helper to format date - replace with actual logic if doctor has hiredDate
  String _formatHiredDate(DateTime? date) {
    if (date == null) {
      // Provide a fallback or indicate missing data
      return 'N/A'; // Or return a placeholder like '7/27/15' if absolutely needed
    }
    // Using intl package for formatting
    return DateFormat('M/d/yy').format(date);
  }

  // Placeholder for getting a role - ideally from Doctor model
  String get _doctorRole => doctor.specialty;

  // Placeholder for contact info - use doctor data primarily
  String get _doctorEmail =>
      doctor.email ?? 'N/A'; // Prefer 'N/A' or empty over fake data
  String get _doctorPhone =>
      doctor.phoneNumber.isNotEmpty ? doctor.phoneNumber : 'N/A';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior:
          Clip.antiAlias, // Ensures InkWell ripple stays within bounds
      child: InkWell(
        onTap:
            () => navigationService.navigateTo(
              '/doctor/details',
              arguments: doctor,
            ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch content horizontally
          children: [
            _buildCardHeader(context, ref, navigationService),
            Expanded(
              // Use Expanded to allow content to fill remaining space
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12,
                ), // Adjust padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _doctorRole, // Use placeholder or actual data
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12), // Spacing before divider
                    const Divider(height: 1),
                    const SizedBox(height: 12), // Spacing after divider
                    _InfoRow(label: 'Department', value: doctor.specialty),
                    const SizedBox(height: 4),
                    // Assuming doctor object has a hiredDate field (DateTime?)
                    // If not, adapt this line or remove it.
                    _InfoRow(
                      label: 'Created at',
                      value: _formatHiredDate(doctor.createdAt),
                    ), // Use actual data
                    const Spacer(), // Pushes contact info to the bottom
                    _ContactInfoRow(
                      icon: Icons.email_outlined,
                      text: _doctorEmail,
                    ),
                    const SizedBox(height: 8),
                    _ContactInfoRow(
                      icon: Icons.phone_outlined,
                      text: _doctorPhone,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    BuildContext context,
    WidgetRef ref,
    NavigationService navigationService,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to top
        children: [
          _DoctorAvatarWithStatus(doctor: doctor),
          _DoctorCardMenuButton(
            doctor: doctor,
            onEdit:
                () => navigationService.navigateTo(
                  '/doctor/edit',
                  arguments: doctor,
                ),
            onDelete: () => _confirmDelete(context, ref, doctor),
          ),
        ],
      ),
    );
  }

  // Extracted helper for showing delete confirmation
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Doctor doctor,
  ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Doctor'),
            content: Text(
              'Are you sure you want to delete ${doctor.name}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    // Check if the dialog was dismissed or cancel was pressed, or if the widget is no longer mounted
    if (shouldDelete != true || !context.mounted) return;

    final notifier = ref.read(doctorNotifierProvider.notifier);
    // Consider showing a loading indicator while deleting
    final result = await notifier.deleteDoctor(doctor.id);

    // Check context.mounted again before showing SnackBar
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? 'Doctor "${doctor.name}" deleted successfully.'
              : 'Error deleting doctor: ${result.error}',
        ),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}

// Doctor Avatar Widget (used within Card Header)
class _DoctorAvatarWithStatus extends StatelessWidget {
  final Doctor doctor;

  const _DoctorAvatarWithStatus({required this.doctor});

  @override
  Widget build(BuildContext context) {
    // Reduced avatar size slightly for better fit in card
    const double avatarRadius = 35;
    const double statusRadius = 10;

    Widget avatarContent;
    ImageProvider? backgroundImage;

    if (doctor.imageUrl != null && doctor.imageUrl!.isNotEmpty) {
      backgroundImage = NetworkImage(doctor.imageUrl!);
      avatarContent = const SizedBox.shrink(); // No child needed if image loads
    } else {
      // Fallback to initials
      backgroundImage = null; // Ensure no background image if using initials
      avatarContent = Center(
        child: Text(
          doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: avatarRadius * 0.8, // Scale font size with radius
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[600],
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none, // Allow status indicator to overflow slightly
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: AppColors.accent, // Fallback background
          backgroundImage: backgroundImage,
          // Handle image loading errors if needed
          onBackgroundImageError: backgroundImage != null ? (_, __) {} : null,
          child: avatarContent,
        ),
        Positioned(
          bottom: -2, // Adjust position slightly
          right: -2,
          child: CircleAvatar(
            radius: statusRadius,
            backgroundColor: Colors.white, // White border around status
            child: CircleAvatar(
              radius: statusRadius - 2, // Inner status color circle
              backgroundColor: doctor.isAvailable ? Colors.green : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

// Menu Button Widget (used within Card Header)
class _DoctorCardMenuButton extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DoctorCardMenuButton({
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.black54),
      tooltip: 'More options', // Accessibility
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder:
          (context) => [
            _buildPopupMenuItem(
              context,
              'edit',
              Icons.edit_outlined,
              'Edit Doctor',
            ),
            _buildPopupMenuItem(
              context,
              'delete',
              Icons.delete_outline,
              'Delete Doctor',
              color: Colors.red,
            ),
          ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    context,
    String value,
    IconData icon,
    String text, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

// Reusable Info Row Widget (used within Card Body)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90, // Keep consistent label width
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Reusable Contact Info Row Widget (used within Card Body)
class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Error View Widget
class ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load doctors',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                // backgroundColor: Theme.of(context).colorScheme.primary,
                // foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
