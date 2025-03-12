import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/features/doctor/view/doctor_profile_screen.dart';
import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'doctor_availability_card.dart';

class DashboardDoctorAvailability extends StatelessWidget {
  const DashboardDoctorAvailability({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cardHeight = constraints.maxWidth < 600 ? 120.0 : 150.0;

      return Consumer<ClinicService>(
        builder: (context, clinicService, _) {
          final availableDoctors = clinicService.getDoctors();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doctor Availability',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: cardHeight,
                child: availableDoctors.isEmpty
                    ? const Center(
                        child: Text('No doctors available',
                            style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableDoctors.length,
                        itemBuilder: (context, index) {
                          final doctor = availableDoctors[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: DoctorAvailabilityCard(
                              doctor: doctor,
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) =>
                                        DoctorProfileScreen(doctor: doctor)));
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    });
  }
}