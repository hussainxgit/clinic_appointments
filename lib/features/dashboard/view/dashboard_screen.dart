import 'package:flutter/material.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'dashboard_search_delegate.dart';
import 'dashboard_stats_section.dart';
import 'dashboard_appointment_chart.dart';
import 'dashboard_doctor_availability.dart';
import 'dashboard_tab_section.dart';
import 'dashboard_quick_add_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isPortrait = context.isPortrait;
    final isTablet = context.isTablet;

    return isPortrait
        ? _buildPortraitLayout(context, isTablet)
        : _buildLandscapeLayout(context, isTablet);
  }

  Widget _buildPortraitLayout(BuildContext context, bool isTablet) {
    final spacing = isTablet ? 20.0 : 24.0;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const DashboardQuickAddDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DashboardStatsSection(),
              SizedBox(height: spacing),
              const DashboardAppointmentChart(),
              SizedBox(height: spacing),
              const DashboardDoctorAvailability(),
              SizedBox(height: isTablet ? 20 : 24),
              const DashboardTabSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, bool isTablet) {
    final padding = 16.0;
    final spacing = isTablet ? 20.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ClinicSearchDelegate(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const DashboardQuickAddDialog(),
        ),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Stats and Chart)
              Expanded(
                flex: isTablet ? 1 : 1,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DashboardStatsSection(),
                        SizedBox(height: spacing),
                        const DashboardAppointmentChart(),
                      ],
                    ),
                  ),
                ),
              ),
              // Right Column (Tabs and Lists)
              Expanded(
                flex: isTablet ? 1 : 1,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DashboardDoctorAvailability(),
                      SizedBox(height: spacing),
                      const DashboardTabSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
