import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/appointment/models/appointment.dart';
import '../../../features/appointment_slot/models/appointment_slot.dart';
import '../../../features/doctor/models/doctor.dart';
import '../../../features/patient/models/patient.dart';
import '../../../shared/services/clinic_service.dart';
import 'custom_app_bar.dart';

class AppointmentSlotPatientsScreen extends StatelessWidget {
  final AppointmentSlot slot;

  const AppointmentSlotPatientsScreen({
    super.key,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final doctorInfo = clinicService.doctorProvider.findDoctorById(slot.doctorId);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Booked Patients',
        subtitle: _buildSubtitle(doctorInfo, slot),
      ),
      body: _buildBody(context, clinicService),
      floatingActionButton: _buildFloatingActionButton(context, clinicService),
    );
  }

  String _buildSubtitle(Doctor? doctor, AppointmentSlot slot) {
    final formattedDate = '${slot.date.day}/${slot.date.month}/${slot.date.year}';
    final doctorName = doctor?.name ?? 'Unknown Doctor';
    return '$doctorName - $formattedDate';
  }

  Widget _buildBody(BuildContext context, ClinicService clinicService) {
    // Get appointments for this slot
    final appointments = clinicService.appointmentProvider.appointments
        .where((appointment) => appointment.appointmentSlotId == slot.id)
        .toList();

    if (appointments.isEmpty) {
      return const Center(
        child: Text(
          'No patients booked for this slot',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Column(
      children: [
        _buildSlotHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildPatientCard(context, appointment, clinicService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSlotHeader(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: ${slot.date.day}/${slot.date.month}/${slot.date.year}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  'Booked: ${slot.bookedPatients}/${slot.maxPatients}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: slot.isFullyBooked ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context, 
    Appointment appointment, 
    ClinicService clinicService
  ) {
    // Find patient details
    final patient = clinicService.patientProvider.patients.firstWhere(
      (p) => p.id == appointment.patientId,
      orElse: () => Patient(
        id: 'unknown',
        name: 'Unknown Patient',
        phone: '',
        registeredAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(patient.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${patient.phone}'),
            Row(
              children: [
                Chip(
                  label: Text(appointment.status),
                  backgroundColor: _getStatusColor(appointment.status),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(appointment.paymentStatus),
                  backgroundColor: appointment.paymentStatus.toLowerCase() == 'paid' 
                    ? Colors.green[100] 
                    : Colors.orange[100],
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(value, appointment, context, clinicService),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel),
                  SizedBox(width: 8),
                  Text('Cancel Appointment'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'updateStatus',
              child: Row(
                children: [
                  Icon(Icons.update),
                  SizedBox(width: 8),
                  Text('Update Status'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'updatePayment',
              child: Row(
                children: [
                  Icon(Icons.payment),
                  SizedBox(width: 8),
                  Text('Update Payment'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToPatientDetails(context, patient.id),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue[100]!;
      case 'completed':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  void _handleAction(
    String action, 
    Appointment appointment, 
    BuildContext context,
    ClinicService clinicService
  ) async {
    switch (action) {
      case 'view':
        _navigateToAppointmentDetails(context, appointment.id);
        break;
      case 'cancel':
        _showCancelConfirmation(context, appointment, clinicService);
        break;
      case 'updateStatus':
        _showUpdateStatusDialog(context, appointment, clinicService);
        break;
      case 'updatePayment':
        _showUpdatePaymentDialog(context, appointment, clinicService);
        break;
    }
  }

  void _navigateToPatientDetails(BuildContext context, String patientId) {
    // Navigate to patient details screen
    // Implementation depends on your navigation setup
  }

  void _navigateToAppointmentDetails(BuildContext context, String appointmentId) {
    // Navigate to appointment details screen
    // Implementation depends on your navigation setup
  }

  void _showCancelConfirmation(
    BuildContext context, 
    Appointment appointment,
    ClinicService clinicService
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Appointment'),
          content: const Text('Are you sure you want to cancel this appointment?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                // Update appointment status to cancelled
                final updatedAppointment = appointment.copyWith(
                  status: 'cancelled',
                );
                
                clinicService.updateAppointment(updatedAppointment).then((result) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result.isSuccess 
                          ? 'Appointment cancelled successfully' 
                          : 'Failed to cancel appointment: ${result.errorMessage}'
                      ),
                      backgroundColor: result.isSuccess ? Colors.green : Colors.red,
                    ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpdateStatusDialog(
    BuildContext context, 
    Appointment appointment,
    ClinicService clinicService
  ) {
    final statusOptions = ['scheduled', 'completed', 'cancelled'];
    String selectedStatus = appointment.status;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Appointment Status'),
              content: DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: statusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedStatus = newValue;
                    });
                  }
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Update'),
                  onPressed: () {
                    final updatedAppointment = appointment.copyWith(
                      status: selectedStatus,
                    );
                    
                    clinicService.updateAppointment(updatedAppointment).then((result) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.isSuccess 
                              ? 'Status updated successfully' 
                              : 'Failed to update status: ${result.errorMessage}'
                          ),
                          backgroundColor: result.isSuccess ? Colors.green : Colors.red,
                        ),
                      );
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpdatePaymentDialog(
    BuildContext context, 
    Appointment appointment,
    ClinicService clinicService
  ) {
    final paymentOptions = ['paid', 'unpaid'];
    String selectedPayment = appointment.paymentStatus;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Payment Status'),
              content: DropdownButton<String>(
                value: selectedPayment,
                isExpanded: true,
                items: paymentOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPayment = newValue;
                    });
                  }
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Update'),
                  onPressed: () {
                    final updatedAppointment = appointment.copyWith(
                      paymentStatus: selectedPayment,
                    );
                    
                    clinicService.updateAppointment(updatedAppointment).then((result) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result.isSuccess 
                              ? 'Payment status updated successfully' 
                              : 'Failed to update payment status: ${result.errorMessage}'
                          ),
                          backgroundColor: result.isSuccess ? Colors.green : Colors.red,
                        ),
                      );
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, ClinicService clinicService) {
    // Only show add patient FAB if slot is not fully booked
    if (slot.isFullyBooked) {
      return null;
    }
    
    return FloatingActionButton(
      onPressed: () => _navigateToAddPatient(context),
      tooltip: 'Add Patient to Slot',
      child: const Icon(Icons.add),
    );
  }

  void _navigateToAddPatient(BuildContext context) {
    // Navigate to add patient screen, passing the slot ID
    // Implementation depends on your navigation setup
    // You could use something like:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => AddAppointmentScreen(slotId: slot.id),
    //   ),
    // );
  }
}