import 'package:flutter/material.dart';

// Custom widget to handle Patient avatar display
class PatientAvatar extends StatelessWidget {
  final String? imageUrl; // URL for the Patient's profile image
  final String name; // Patient's name for generating initials
  final int? index; // Index for generating a unique avatar background color
  final double radius; // Optional radius for the CircleAvatar (default 40)

  const PatientAvatar({
    super.key,
    required this.name,
    this.index,
    this.imageUrl,
    this.radius = 40,
  });

  // Helper method to generate a unique color based on index
  Color _getAvatarColor(int index) {
    // Use a simple hash function to generate a color based on the index
    final hue =
        (index * 137) % 360; // 137 is a prime number for good distribution
    return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.9).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: _getAvatarColor(index ?? 7),
      backgroundImage: imageUrl == null || imageUrl!.isEmpty
          ? null
          : NetworkImage(imageUrl!),
      radius: radius,
      child: imageUrl == null || imageUrl!.isEmpty
          ? Text(
              name.isNotEmpty
                  ? name[0].toUpperCase()
                  : 'U', // Fallback to 'U' if name is empty
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            )
          : null,
    );
  }
}
