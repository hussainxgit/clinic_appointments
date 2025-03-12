import 'package:flutter/material.dart';
import '../models/doctor.dart';
import 'doctor_card.dart';

class DoctorsGridView extends StatelessWidget {
  final List<Doctor> doctors;

  const DoctorsGridView({super.key, required this.doctors});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine the number of columns based on screen width
        int crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          padding: const EdgeInsets.all(16.0), // Add padding for better spacing
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8, // Maintain card proportions
          ),
          itemCount: doctors.length,
          itemBuilder: (context, index) => DoctorCard(
            doctor: doctors[index],
            index: index,
          ),
        );
      },
    );
  }

  // Calculate the number of columns based on available width
  int _calculateCrossAxisCount(double width) {
    if (width < 768) {
      // For smaller screens (though targeting iPad/PC, this is a fallback)
      return 2;
    } else if (width < 1024) {
      // iPad-sized screens (e.g., 9.7" iPad at 768px width)
      return 3;
    } else if (width < 1440) {
      // Larger tablets or small PC monitors
      return 4;
    } else {
      // Large PC monitors (e.g., 1440p or higher)
      return 5;
    }
  }
}