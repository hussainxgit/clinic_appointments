import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/appointment/domain/entities/appointment.dart';
import '../../../../features/doctor/domain/entities/doctor.dart';
import '../../../../features/doctor/presentation/provider/doctor_notifier.dart';
import '../../../appointment/services/appointment_service.dart';

class WeeklyAppointmentsChart extends ConsumerStatefulWidget {
  const WeeklyAppointmentsChart({super.key});

  @override
  ConsumerState<WeeklyAppointmentsChart> createState() =>
      _WeeklyAppointmentsChartState();
}

class _WeeklyAppointmentsChartState
    extends ConsumerState<WeeklyAppointmentsChart> {
  String? _selectedDoctorId;
  List<Appointment> _appointments = [];
  List<int> _appointmentCounts = List.filled(7, 0);
  bool _isLoading = false;

  final Color _barColor = Colors.blue;
  final Color _touchedBarColor = Colors.indigo;
  final Color _barBackgroundColor = Colors.black12;

  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _initDoctors();
  }

  void _initDoctors() {
    // Delay to ensure providers are ready
    Future.microtask(() {
      final doctorState = ref.read(doctorNotifierProvider);
      if (doctorState.doctors.isNotEmpty) {
        setState(() {
          _selectedDoctorId = doctorState.doctors.first.id;
        });
        _loadAppointments();
      }
    });
  }

  Future<void> _loadAppointments() async {
    if (_selectedDoctorId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch appointments directly from the service
      final appointmentService = ref.read(appointmentServiceProvider);
      final result = await appointmentService.getCombinedAppointments(
        doctorId: _selectedDoctorId,
      );

      if (result.isSuccess) {
        final appointments =
            result.data
                .map((item) => item['appointment'] as Appointment)
                .where((appointment) => _isInCurrentWeek(appointment.dateTime))
                .toList();

        // Count appointments by day of week
        List<int> dailyCounts = List.filled(7, 0);
        for (var appointment in appointments) {
          int dayIndex = appointment.dateTime.weekday - 1;
          dailyCounts[dayIndex]++;
        }

        setState(() {
          _appointments = appointments;
          _appointmentCounts = dailyCounts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    final endOfWeek = startOfWeek.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    return date.isAfter(startOfWeek) && date.isBefore(endOfWeek);
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorNotifierProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Week Appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              doctorState.isLoading
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(),
                  )
                  : _buildDoctorSelector(doctorState.doctors),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _appointments.isEmpty
                    ? const Center(
                      child: Text('No appointments data available'),
                    )
                    : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorSelector(List<Doctor> doctors) {
    return DropdownButton<String>(
      value: _selectedDoctorId,
      hint: const Text('Select Doctor'),
      underline: Container(),
      icon: const Icon(Icons.arrow_drop_down),
      onChanged: (String? newValue) {
        setState(() {
          _selectedDoctorId = newValue;
          _touchedIndex = -1;
        });
        _loadAppointments();
      },
      items:
          doctors.map<DropdownMenuItem<String>>((Doctor doctor) {
            return DropdownMenuItem<String>(
              value: doctor.id,
              child: Text(doctor.name),
            );
          }).toList(),
    );
  }

  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: BarChart(
        _createBarChartData(),
        swapAnimationDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  BarChartData _createBarChartData() {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.blueGrey,
          tooltipHorizontalAlignment: FLHorizontalAlignment.right,
          tooltipMargin: -10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final weekDay = _getWeekdayName(group.x);
            final appointments = rod.toY.toInt();

            return BarTooltipItem(
              '$weekDay\n',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '$appointments appointments',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              _touchedIndex = -1;
              return;
            }
            _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _getBottomTitles,
            reservedSize: 38,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: _getLeftTitles,
            reservedSize: 40,
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: _createBarGroups(),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: 5,
        getDrawingHorizontalLine:
            (value) =>
                FlLine(color: Colors.grey.withAlpha((0.2 * 255).toInt()), strokeWidth: 1),
      ),
      maxY: _getMaxY(),
    );
  }

  // Remaining methods unchanged
  // ...

  List<BarChartGroupData> _createBarGroups() {
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: _appointmentCounts[index].toDouble(),
            color: _touchedIndex == index ? _touchedBarColor.withAlpha((0.8 * 255).toInt()) : _barColor,
            width: 20,
            borderSide:
                _touchedIndex == index
                    ? BorderSide(
                      color: _touchedBarColor.withAlpha((0.8 * 255).toInt()),
                      width: 2,
                    )
                    : BorderSide.none,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _getMaxY(),
              color: _barBackgroundColor,
            ),
          ),
        ],
      );
    });
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);

    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final index = value.toInt();

    if (index >= 0 && index < weekdays.length) {
      return SideTitleWidget(
        meta: meta,
        space: 16,
        child: Text(weekdays[index], style: style),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    if (value % 5 != 0) return const SizedBox.shrink();

    return SideTitleWidget(
      meta: meta,
      space: 8,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  String _getWeekdayName(int index) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    if (index >= 0 && index < weekdays.length) {
      return weekdays[index];
    }

    return '';
  }

  double _getMaxY() {
    if (_appointmentCounts.isEmpty) return 20;

    final maxAppointments = _appointmentCounts.fold<int>(
      0,
      (prev, count) => count > prev ? count : prev,
    );

    // Round up to nearest multiple of 5
    return ((maxAppointments / 5).ceil() * 5).toDouble();
  }
}
