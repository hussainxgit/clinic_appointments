import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:clinic_appointments/shared/services/clinic_service.dart';

class DashboardAppointmentChart extends StatefulWidget {
  const DashboardAppointmentChart({super.key});

  @override
  State<DashboardAppointmentChart> createState() => _DashboardAppointmentChartState();
}

class _DashboardAppointmentChartState extends State<DashboardAppointmentChart> {
  bool _showWeeklyView = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final chartHeight = constraints.maxWidth < 600 ? 250.0 : 300.0;

      return Container(
        height: chartHeight,
        padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Appoints. Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                constraints.maxWidth < 400
                    ? PopupMenuButton<bool>(
                        initialValue: _showWeeklyView,
                        onSelected: (value) {
                          setState(() {
                            _showWeeklyView = value;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: false,
                            child: Text('Monthly'),
                          ),
                          const PopupMenuItem(
                            value: true,
                            child: Text('Weekly'),
                          ),
                        ],
                        child: const Icon(Icons.more_vert),
                      )
                    : SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Monthly')),
                          ButtonSegment(value: true, label: Text('Weekly')),
                        ],
                        selected: {_showWeeklyView},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _showWeeklyView = newSelection.first;
                          });
                        },
                      ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ClinicService>(
                builder: (context, service, _) {
                  final spots = _generateChartData(service);
                  final maxY = _calculateMaxY(spots);

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY > 50 ? 20 : 10,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.shade200,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: constraints.maxWidth < 500 ? 2 : 1,
                            getTitlesWidget: (value, meta) {
                              final labels = _showWeeklyView
                                  ? [
                                      'Mon',
                                      'Tue',
                                      'Wed',
                                      'Thu',
                                      'Fri',
                                      'Sat',
                                      'Sun'
                                    ]
                                  : [
                                      'Jan',
                                      'Feb',
                                      'Mar',
                                      'Apr',
                                      'May',
                                      'Jun',
                                      'Jul',
                                      'Aug',
                                      'Sep',
                                      'Oct',
                                      'Nov',
                                      'Dec'
                                    ];
                              final index = value.toInt();
                              if (index >= 0 && index < labels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(labels[index],
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: constraints.maxWidth < 500
                                              ? 12
                                              : 14)),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: maxY > 50 ? 20 : 10,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(value.toInt().toString(),
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: constraints.maxWidth < 500
                                          ? 12
                                          : 14)),
                            ),
                            reservedSize: constraints.maxWidth < 500 ? 30 : 40,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: _showWeeklyView ? 6 : 11,
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Theme.of(context).primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color:
                                Theme.of(context).primaryColor.withValues(alpha:0.2),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      );
    });
  }

  List<FlSpot> _generateChartData(ClinicService service) {
    // Get all appointments from the service
    final appointments = service.appointmentProvider.appointments;

    if (_showWeeklyView) {
      // For weekly view, we'll group by day of week (1-7, Monday to Sunday)
      final Map<int, int> countByDayOfWeek = {
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
        6: 0,
        7: 0
      };

      // Get current date to calculate current week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Count appointments for the current week
      for (final appointment in appointments) {
        final appointmentDate = appointment.dateTime;

        // Check if the appointment is in the current week
        if (appointmentDate.isAfter(startOfWeek) &&
            appointmentDate.isBefore(endOfWeek.add(const Duration(days: 1)))) {
          // Get day of week (1-7, where 1 is Monday)
          final dayOfWeek = appointmentDate.weekday;
          countByDayOfWeek[dayOfWeek] = (countByDayOfWeek[dayOfWeek] ?? 0) + 1;
        }
      }

      // Convert to FlSpot list (x: 0-6 for Mon-Sun, y: appointment count)
      return countByDayOfWeek.entries
          .map((entry) =>
              FlSpot((entry.key - 1).toDouble(), entry.value.toDouble()))
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    } else {
      // For monthly view, we'll group by month (1-12)
      final Map<int, int> countByMonth = {
        1: 0,
        2: 0,
        3: 0,
        4: 0,
        5: 0,
        6: 0,
        7: 0,
        8: 0,
        9: 0,
        10: 0,
        11: 0,
        12: 0
      };

      // Get current year
      final currentYear = DateTime.now().year;

      // Count appointments for the current year
      for (final appointment in appointments) {
        final appointmentDate = appointment.dateTime;

        // Check if the appointment is in the current year
        if (appointmentDate.year == currentYear) {
          final month = appointmentDate.month;
          countByMonth[month] = (countByMonth[month] ?? 0) + 1;
        }
      }

      // Convert to FlSpot list (x: 0-11 for Jan-Dec, y: appointment count)
      return countByMonth.entries
          .map((entry) =>
              FlSpot((entry.key - 1).toDouble(), entry.value.toDouble()))
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));
    }
  }

  // Calculate the Y-axis max value dynamically
  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 10.0; // Default if no data

    // Find the maximum Y value
    double maxY =
        spots.map((spot) => spot.y).reduce((max, y) => y > max ? y : max);

    // Round up to the nearest 10
    return (maxY / 10).ceil() * 10.0;
  }
}