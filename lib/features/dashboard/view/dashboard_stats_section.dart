import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'stat_card.dart';

class DashboardStatsSection extends StatelessWidget {
  const DashboardStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        final stats = [
          StatCard(
            title: 'Patients',
            value: clinicService.getTotalPatients().toString(),
            icon: Icons.people_alt_rounded,
            color: Colors.blue.shade700,
            trend: '',
            isPositiveTrend: true,
          ),
          StatCard(
            title: 'Appointments',
            value: clinicService.getTotalAppointments().toString(),
            icon: Icons.calendar_month_rounded,
            color: Colors.green.shade700,
            trend: '',
            isPositiveTrend: true,
          ),
          StatCard(
            title: "Today's Visits",
            value: clinicService.getTodaysAppointments().length.toString(),
            icon: Icons.event_available_rounded,
            color: Colors.orange.shade700,
            trend: '',
            isPositiveTrend: true,
          ),
          StatCard(
            title: 'Cancelled',
            value: clinicService.getCancelledAppointments().length.toString(),
            icon: Icons.cancel_rounded,
            color: Colors.red.shade700,
            trend: '',
            isPositiveTrend: false,
          ),
        ];

        return LayoutBuilder(builder: (context, constraints) {
          // Adjust the grid based on available width
          final crossAxisCount = constraints.maxWidth < 500
              ? 2
              : constraints.maxWidth < 900
                  ? 2
                  : 4;

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth < 500 ? 1 : 1.5,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stats.length,
            itemBuilder: (context, index) => stats[index],
          );
        });
      },
    );
  }
}