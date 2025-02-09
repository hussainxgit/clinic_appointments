import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../appointment/models/appointment.dart';
import '../../appointment/view/appointments_list_view.dart';
import 'stat_card.dart';

class DashboardScreen extends StatelessWidget {
  final int totalPatients;
  final int totalAppointments;
  final int activeAppointmentsToday;
  final int completedAppointments;
  final int cancelledAppointments;
  final List<Appointment> appointments;

  const DashboardScreen({
    super.key,
    required this.totalPatients,
    required this.totalAppointments,
    required this.activeAppointmentsToday,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatsRow(context),
            _buildActionsAndAppointments(context),
          ],
        ),
      ),
    );
  }

  /// Builds the row of statistical cards.
  Widget _buildStatsRow(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final stats = [
      StatData(
        title: 'Total Patients',
        value: clinicService.getTotalPatients().toString(),
        icon: Icons.people,
        color: Colors.blue,
      ),
      StatData(
        title: 'Total Appointments',
        value: clinicService.getTotalAppointments().toString(),
        icon: Icons.calendar_today,
        color: Colors.green,
      ),
      StatData(
        title: "Today's Appointments",
        value: clinicService.getTodaysAppointments().length.toString(),
        icon: Icons.event_available,
        color: Colors.orange,
      ),
      StatData(
        title: 'Cancelled Appointments',
        value: clinicService.getCancelledAppointments().length.toString(),
        icon: Icons.cancel,
        color: Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return isSmallScreen
            ? Column(
                children: stats
                    .map((stat) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: StatCard(
                            title: stat.title,
                            value: stat.value,
                            icon: stat.icon,
                            color: stat.color,
                          ),
                        ))
                    .toList(),
              )
            : Row(
                children: stats
                    .map((stat) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: StatCard(
                              title: stat.title,
                              value: stat.value,
                              icon: stat.icon,
                              color: stat.color,
                            ),
                          ),
                        ))
                    .toList(),
              );
      },
    );
  }

  /// Builds the actions grid and recent appointments list.
  Widget _buildActionsAndAppointments(BuildContext context) {
    return Consumer<ClinicService>(
      builder: (context, clinicService, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 1,
                child: _buildActionsGrid(context),
              ),
              const SizedBox(width: 16),
              Flexible(
                flex: 1,
                child: _buildRecentAppointments(context, clinicService),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the actions grid.
  Widget _buildActionsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Actions",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
        ),
        Row(
          spacing: 16,
          children: [
            ElevatedButton(
              onPressed: () {
                print('pressed');
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Square buttons
                ),
              ),
              child: Text('Button 1'),
            ),
            ElevatedButton(
              onPressed: () {
                print('pressed');
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Square buttons
                ),
              ),
              child: Text('Button 2'),
            )
          ],
        )
      ],
    );
  }

  /// Builds the recent appointments list.
  Widget _buildRecentAppointments(
      BuildContext context, ClinicService clinicService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Recently Taken Appointments",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: AppointmentsListView(
            appointments: clinicService.appointmentProvider.appointments,
          ),
        ),
      ],
    );
  }
}

/// Helper class to hold stat card data.
class StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
