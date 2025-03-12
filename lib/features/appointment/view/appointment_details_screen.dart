import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/appointment/models/appointment.dart';
import '../../../features/appointment_slot/models/appointment_slot.dart';
import '../../../features/doctor/models/doctor.dart';
import '../../../features/patient/models/patient.dart';
import '../../../shared/services/clinic_service.dart';
import '../../appointment_slot/view/custom_app_bar.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    
    // Get appointment details
    final appointment = clinicService.appointmentProvider.appointments.firstWhere(
      (a) => a.id == widget.appointmentId,
      orElse: () => throw Exception('Appointment not found'),
    );
    
    // Get patient details
    final patient = clinicService.patientProvider.patients.firstWhere(
      (p) => p.id == appointment.patientId,
      orElse: () => Patient(
        id: 'unknown',
        name: 'Unknown Patient',
        phone: '',
        registeredAt: DateTime.now(),
      ),
    );
    
    // Get doctor details
    final doctor = clinicService.doctorProvider.findDoctorById(appointment.doctorId) ?? 
      Doctor(
        id: 'unknown',
        name: 'Unknown Doctor',
        specialty: '',
        phoneNumber: '',
      );
    
    // Get slot details
    final slot = clinicService.appointmentSlotProvider.slots.firstWhere(
      (s) => s.id == appointment.appointmentSlotId,
      orElse: () => throw Exception('Appointment slot not found'),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Appointment Details',
        subtitle: 'Ref: ${appointment.id}',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit appointment',
            onPressed: () => _navigateToEditAppointment(context, appointment),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(
              value, appointment, context, clinicService),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cancel Appointment'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Appointment'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context, appointment),
            const SizedBox(height: 16),
            _buildPatientCard(context, patient),
            const SizedBox(height: 16),
            _buildDoctorCard(context, doctor),
            const SizedBox(height: 16),
            _buildAppointmentDetailsCard(context, appointment, slot),
            const SizedBox(height: 16),
            _buildActionButtons(context, appointment, clinicService),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Appointment appointment) {
    final statusColor = _getStatusColor(appointment.status);
    final paymentStatusColor = appointment.paymentStatus.toLowerCase() == 'paid' 
      ? Colors.green 
      : Colors.orange;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusChip(
              'Status',
              appointment.status,
              statusColor,
            ),
            _buildStatusChip(
              'Payment',
              appointment.paymentStatus,
              paymentStatusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Chip(
          label: Text(
            value,
            style: TextStyle(
              color: color == Colors.white ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ],
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Patient Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.person),
                  tooltip: 'View patient profile',
                  onPressed: () => _navigateToPatientDetails(context, patient.id),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Name', patient.name),
            _buildInfoRow('Phone', patient.phone),
            if (patient.email != null) _buildInfoRow('Email', patient.email!),
            _buildInfoRow('Gender', patient.gender.toString().split('.').last),
            if (patient.dateOfBirth != null)
              _buildInfoRow('Age', '${_calculateAge(patient.dateOfBirth!)} years'),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Doctor Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.medical_services),
                  tooltip: 'View doctor profile',
                  onPressed: () => _navigateToDoctorDetails(context, doctor.id),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Name', doctor.name),
            _buildInfoRow('Specialty', doctor.specialty),
            _buildInfoRow('Phone', doctor.phoneNumber),
            if (doctor.email != null) _buildInfoRow('Email', doctor.email!),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentDetailsCard(
    BuildContext context, 
    Appointment appointment,
    AppointmentSlot slot
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appointment Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Date',
              '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year}',
            ),
            _buildInfoRow(
              'Slot ID',
              appointment.appointmentSlotId,
            ),
            _buildInfoRow(
              'Slot Capacity',
              '${slot.bookedPatients}/${slot.maxPatients} patients',
            ),
            if (appointment.notes != null && appointment.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(appointment.notes ?? ''),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, 
    Appointment appointment,
    ClinicService clinicService
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.update),
            label: const Text('Update Status'),
            onPressed: () => _showUpdateStatusDialog(context, appointment, clinicService),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Update Payment'),
            onPressed: () => _showUpdatePaymentDialog(context, appointment, clinicService),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToPatientDetails(BuildContext context, String patientId) {
    // Navigate to patient details
    // Implement based on your navigation structure
  }

  void _navigateToDoctorDetails(BuildContext context, String doctorId) {
    // Navigate to doctor details
    // Implement based on your navigation structure
  }

  void _navigateToEditAppointment(BuildContext context, Appointment appointment) {
    // Navigate to edit appointment
    // Implement based on your navigation structure
  }

  void _handleAction(
    String action, 
    Appointment appointment, 
    BuildContext context,
    ClinicService clinicService
  ) {
    switch (action) {
      case 'cancel':
        _showCancelConfirmation(context, appointment, clinicService);
        break;
      case 'delete':
        _showDeleteConfirmation(context, appointment, clinicService);
        break;
    }
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
                  if (result.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {}); // Refresh UI
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to cancel appointment: ${result.errorMessage}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context, 
    Appointment appointment,
    ClinicService clinicService
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: const Text(
            'Are you sure you want to permanently delete this appointment? This action cannot be undone.'
          ),
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
                clinicService.removeAppointment(appointment.id).then((result) {
                  Navigator.of(context).pop();
                  if (result.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navigate back to previous screen
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete appointment: ${result.errorMessage}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Current status:'),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(appointment.status),
                    backgroundColor: _getStatusColor(appointment.status),
                  ),
                  const SizedBox(height: 16),
                  const Text('New status:'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
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
                ],
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
                      if (result.isSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Status updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {}); // Refresh UI
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update status: ${result.errorMessage}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Current payment status:'),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(appointment.paymentStatus),
                    backgroundColor: appointment.paymentStatus.toLowerCase() == 'paid' 
                      ? Colors.green 
                      : Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  const Text('New payment status:'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
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
                ],
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
                      if (result.isSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment status updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {}); // Refresh UI
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update payment status: ${result.errorMessage}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}