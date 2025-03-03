import 'package:flutter/material.dart';
import '../models/doctor.dart';
import 'doctor_card.dart';


// Refactored grid view for displaying doctors
class DoctorsGridView extends StatelessWidget {
  final List<Doctor> doctors;

  const DoctorsGridView({super.key, required this.doctors});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: doctors.length,
      itemBuilder: (context, index) => DoctorCard(
        doctor: doctors[index],
        index: index,
      ),
    );
  }
}