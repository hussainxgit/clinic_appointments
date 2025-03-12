import 'package:clinic_appointments/features/appointment/view/appointment_card.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/clinic_service.dart';
import '../../doctor/models/doctor.dart';
import '../../patient/models/patient.dart';
import '../models/appointment.dart';

class AppointmentsGroupedView extends StatelessWidget {
  final DateTimeRange dateRange;
  final String? doctorId;
  final String? status;
  final String? paymentStatus;

  const AppointmentsGroupedView({
    super.key, 
    required this.dateRange,
    this.doctorId,
    this.status,
    this.paymentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<ClinicService>(builder: (context, clinicService, child) {
      // Get all appointments
      var allAppointments = clinicService.getCombinedAppointments();
      
      // Apply filters
      final filteredAppointments = _applyFilters(allAppointments);
      
      // Group by date
      final groupedAppointments = _groupAppointmentsByDate(filteredAppointments);
      
      if (groupedAppointments.isEmpty) {
        return _buildEmptyState(theme, colorScheme);
      }
      
      // Get sorted dates for consistent order
      final sortedDates = groupedAppointments.keys.toList()
        ..sort((a, b) => a.compareTo(b));
      
      return ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dateAppointments = groupedAppointments[date]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date header with divider
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colorScheme.outline.withValues(alpha:0.5),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _formatDateHeader(date),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colorScheme.outline.withValues(alpha:0.5),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Appointment cards for this date
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _calculateCrossAxisCount(context),
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: dateAppointments.length,
                itemBuilder: (context, appointmentIndex) {
                  final appointment = dateAppointments[appointmentIndex]['appointment'] as Appointment;
                  final patient = dateAppointments[appointmentIndex]['patient'] as Patient;
                  final doctor = dateAppointments[appointmentIndex]['doctor'] as Doctor;
                  return AppointmentCard(
                    appointment: appointment,
                    patient: patient,
                    doctor: doctor,
                    index: appointmentIndex,
                  );
                },
              ),
              
              // Add spacing after each date group
              const SizedBox(height: 8),
            ],
          );
        },
      );
    });
  }

  // Format date header with relative time qualifiers
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return "Today - ${date.dateOnly()}";
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return "Tomorrow - ${date.dateOnly()}";
    } else {
      return date.dateOnly();
    }
  }

  // Group appointments by date for display
  Map<DateTime, List<Map<String, dynamic>>> _groupAppointmentsByDate(
      List<Map<String, dynamic>> appointments) {
    final grouped = <DateTime, List<Map<String, dynamic>>>{};
    
    for (final appointment in appointments) {
      final appt = appointment['appointment'] as Appointment;
      final date = DateTime(
        appt.dateTime.year,
        appt.dateTime.month,
        appt.dateTime.day,
      );
      
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      
      grouped[date]!.add(appointment);
    }
    
    return grouped;
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> appointments) {
    return appointments.where((item) {
      final appointment = item['appointment'] as Appointment;
      final doctor = item['doctor'] as Doctor;
      
      // Filter by date range
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );
      
      final startDate = DateTime(
        dateRange.start.year,
        dateRange.start.month,
        dateRange.start.day,
      );
      
      final endDate = DateTime(
        dateRange.end.year,
        dateRange.end.month,
        dateRange.end.day,
      );
      
      if (date.isBefore(startDate) || date.isAfter(endDate)) {
        return false;
      }
      
      // Filter by doctor
      if (doctorId != null && doctor.id != doctorId) {
        return false;
      }
      
      // Filter by appointment status
      if (status != null && appointment.status != status) {
        return false;
      }
      
      // Filter by payment status
      if (paymentStatus != null && appointment.paymentStatus != paymentStatus) {
        return false;
      }
      
      return true;
    }).toList();
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width > 1200) {
      return 4;
    } else if (width > 900) {
      return 3;
    } else if (width > 600) {
      return 2;
    } else {
      return 1;
    }
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No appointments found with current filters.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or date range',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}