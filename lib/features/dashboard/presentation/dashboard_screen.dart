import 'package:clinic_appointments/features/dashboard/presentation/widgets/advertising_widget.dart';
import 'package:clinic_appointments/features/dashboard/presentation/widgets/dashboard_statistics.dart';
import 'package:flutter/material.dart';
import 'widgets/appointments_table_widget.dart';
import 'widgets/upcoming_appointments_card.dart';
import 'widgets/weekly_appointments_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        toolbarHeight: 72,
        leadingWidth: 140, // Added to give more space for the larger logo
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset('assets/app_logo_wide.png', width: 120),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue[800],
                backgroundColor: Colors.blue[50],
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                elevation: 0,
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            isWideScreen
                ? _buildWideLayout(context)
                : _buildNarrowLayout(context),
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const DashboardStatistics(),
              const SizedBox(height: 24),
              Expanded(child: AdvertisingWidget()),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: WeeklyAppointmentsChart()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: UpcomingAppointmentsWidget()),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: AppointmentsTableWidget()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardStatistics(),
          const SizedBox(height: 24),
          Container(
            height:
                200.0, // Keeping this fixed as it's likely an intentional design choice
            margin: const EdgeInsets.only(bottom: 24.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Statistics',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                0.3, // 30% of screen height
            child: WeeklyAppointmentsChart(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: UpcomingAppointmentsWidget(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: AppointmentsTableWidget(),
          ),
        ],
      ),
    );
  }
}
