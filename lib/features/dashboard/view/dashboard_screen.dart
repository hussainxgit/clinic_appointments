import 'package:clinic_appointments/features/dashboard/view/recent_appointments_list_view.dart';
import 'package:clinic_appointments/shared/provider/clinic_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'stat_card.dart';
import 'upcoming_slots_list_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            StatsRow(),
            AppointmentListAndAppointmentSlotList(),
          ],
        ),
      ),
    );
  }
}

class StatsRow extends StatelessWidget {
  const StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final stats = [
      StatData(
        title: 'Number Of Patients',
        value: clinicService.getTotalPatients().toString(),
        icon: Icons.people,
        color: Colors.blue,
      ),
      StatData(
        title: 'Number Of Appointments',
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
}

class AppointmentListAndAppointmentSlotList extends StatelessWidget {
  const AppointmentListAndAppointmentSlotList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: RecentAppointmentSlotList(),
          ),
          const SizedBox(width: 16),
          Flexible(flex: 1, child: RecentAppointments()),
        ],
      ),
    );
  }
}

class RecentAppointmentSlotList extends StatelessWidget {
  const RecentAppointmentSlotList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "Recent Appointment Slots",
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: UpcomingSlotsListView(),
        ),
      ],
    );
  }
}

class RecentAppointments extends StatelessWidget {
  const RecentAppointments({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Consumer<ClinicService>(
              builder: (context, clinicServiecProvider, child) {
            final combinedAppointments =
                clinicServiecProvider.getCombinedAppointments();
            return RecentAppointmentsListView(
                combinedAppointments: combinedAppointments);
          }),
        ),
      ],
    );
  }
}

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
