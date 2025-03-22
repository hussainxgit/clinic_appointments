import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../appointment/domain/entities/appointment.dart';
import '../../../appointment/presentation/providers/appointment_notifier.dart';

class AppointmentsTableWidget extends ConsumerWidget {
  const AppointmentsTableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentNotifierProvider);
    final appointments = appointmentState.appointments;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Appointments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed:
                      () => ref
                          .read(navigationServiceProvider)
                          .navigateTo('/appointment/list'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              // Add Expanded here to allow the table to take full height
              child:
                  appointmentState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : appointmentState.error != null
                      ? Center(child: Text('Error: ${appointmentState.error}'))
                      : _buildAppointmentTable(context, ref, appointments),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentTable(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> appointments,
  ) {
    if (appointments.isEmpty) {
      return const Center(child: Text('No appointments found'));
    }

    return SizedBox.expand(
      child: DataTable(
        dividerThickness: 0.2,
        columnSpacing: 20,
        headingRowHeight: 50,
        dataRowMaxHeight: 60,
        columns: const [
          DataColumn(label: Text('PATIENT NAME')),
          DataColumn(label: Text('PHONE NUMBER')),
          DataColumn(label: Text('DATE')),
          DataColumn(label: Text('TIME')),
          DataColumn(label: Text('STATUS')),
          DataColumn(label: Text('ACTION')),
        ],
        rows:
            appointments.map((item) {
              final appointment = item['appointment'] as Appointment;
              final patient = item['patient'];

              final dateTime = appointment.dateTime;
              final date =
                  '${_getMonthName(dateTime.month)} ${dateTime.day}th, ${dateTime.year}';
              final time =
                  '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
              final (statusText, statusColor, bgColor) = _getStatusInfo(
                appointment.status,
              );

              return DataRow(
                cells: [
                  DataCell(Text(patient?.name ?? 'Unknown')),
                  DataCell(Text(patient?.phone ?? '')),
                  DataCell(Text(date)),
                  DataCell(Text(time)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.visibility_outlined,
                            color: Colors.blue,
                          ),
                          onPressed: () => _viewAppointment(ref, item),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.green,
                          ),
                          onPressed: () => _editAppointment(ref, item),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed:
                              () =>
                                  _confirmDeleteAppointment(context, ref, item),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  (String, Color, Color) _getStatusInfo(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return ('Pending', Colors.amber[700]!, Colors.amber.withOpacity(0.2));
      case AppointmentStatus.completed:
        return ('Completed', Colors.blue[700]!, Colors.blue.withOpacity(0.2));
      default:
        return ('Cancelled', Colors.red[700]!, Colors.red.withOpacity(0.2));
    }
  }

  void _viewAppointment(WidgetRef ref, Map<String, dynamic> item) {
    ref
        .read(navigationServiceProvider)
        .navigateTo('/appointment/details', arguments: item);
  }

  void _editAppointment(WidgetRef ref, Map<String, dynamic> item) {
    ref
        .read(navigationServiceProvider)
        .navigateTo('/appointment/edit', arguments: item);
  }

  void _confirmDeleteAppointment(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    final appointment = item['appointment'] as Appointment;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Cancellation'),
            content: const Text(
              'Are you sure you want to cancel this appointment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteAppointment(context, ref, appointment.id);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteAppointment(
    BuildContext context,
    WidgetRef ref,
    String appointmentId,
  ) async {
    final result = await ref
        .read(appointmentNotifierProvider.notifier)
        .cancelAppointment(appointmentId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isFailure
              ? 'Error: ${result.error}'
              : 'Appointment cancelled successfully',
        ),
        backgroundColor: result.isFailure ? Colors.red : Colors.green,
      ),
    );
  }
}

int min(int a, int b) => a < b ? a : b;
