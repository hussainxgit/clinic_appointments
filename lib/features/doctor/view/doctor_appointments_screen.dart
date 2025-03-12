import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/clinic_service.dart';
import '../../appointment/models/appointment.dart';
import '../../appointment/view/appointment_details_screen.dart';
import '../../patient/models/patient.dart';
import '../models/doctor.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  final String doctorId;

  const DoctorAppointmentsScreen({
    super.key,
    required this.doctorId,
  });

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer<ClinicService>(
      builder: (context, clinicService, _) {
        // Get doctor details
        final doctor = clinicService.getDoctors().firstWhere(
              (d) => d.id == widget.doctorId,
              orElse: () => Doctor(
                id: 'unknown',
                name: 'Unknown Doctor',
                specialty: '',
                phoneNumber: '',
              ),
            );

        if (doctor.id == 'unknown') {
          return const Center(
            child: Text('Doctor not found'),
          );
        }

        return Column(
          children: [
            _buildDoctorHeader(doctor),
            _buildDateSelector(),
            Expanded(
              child: _buildAppointmentsList(clinicService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorHeader(Doctor doctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                doctor.imageUrl != null && doctor.imageUrl!.isNotEmpty
                    ? NetworkImage(doctor.imageUrl!)
                    : null,
            child: doctor.imageUrl == null || doctor.imageUrl!.isEmpty
                ? Text(doctor.name.substring(0, 1))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  doctor.specialty,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      doctor.isAvailable ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: doctor.isAvailable ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      doctor.isAvailable ? 'Available' : 'Not Available',
                      style: TextStyle(
                        color: doctor.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          GestureDetector(
            onTap: _selectDate,
            child: Text(
              _selectedDate.dateOnly(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(ClinicService clinicService) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get appointments for this doctor on selected date
    final combinedAppointments = clinicService
        .getCombinedAppointmentsByDate(_selectedDate)
        .where((combined) => combined['doctor'].id == widget.doctorId)
        .toList();

    if (combinedAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments scheduled',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'for ${_selectedDate.dateOnly()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: combinedAppointments.length,
      itemBuilder: (context, index) {
        final appointment =
            combinedAppointments[index]['appointment'] as Appointment;
        final patient = combinedAppointments[index]['patient'] as Patient;

        return AppointmentListItem(
          appointment: appointment,
          patient: patient,
          onStatusChange: (newStatus) =>
              _updateAppointmentStatus(appointment, newStatus),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }


  Future<void> _updateAppointmentStatus(
      Appointment appointment, String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    // Resolve ClinicService and ScaffoldMessenger before the async gap
    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Create updated appointment
    final updatedAppointment = appointment.copyWith(status: newStatus);

    try {
      final result = await clinicService.updateAppointment(updatedAppointment);

      if (result.isSuccess) {
        setState(() {
          // Refresh the UI
        });
      }
    } catch (e) {
      // Use the pre-resolved ScaffoldMessenger
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error updating appointment: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class AppointmentListItem extends StatelessWidget {
  final Appointment appointment;
  final Patient patient;
  final Function(String) onStatusChange;

  const AppointmentListItem({
    super.key,
    required this.appointment,
    required this.patient,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AppointmentDetailsScreen(
                appointmentId: appointment.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appointment.dateTime.dateOnly(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    patient.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text(patient.phone),
                ],
              ),
              if (appointment.notes != null &&
                  appointment.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        appointment.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.payment, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Payment: ${appointment.paymentStatus}',
                    style: TextStyle(
                      color: appointment.paymentStatus == 'paid'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    IconData chipIcon;

    switch (appointment.status.toLowerCase()) {
      case 'scheduled':
        chipColor = Colors.blue;
        chipIcon = Icons.schedule;
        break;
      case 'completed':
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help;
    }

    return Chip(
      label: Text(
        appointment.status,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
      avatar: Icon(chipIcon, color: Colors.white, size: 16),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Different actions based on status
    if (appointment.status.toLowerCase() == 'scheduled') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => onStatusChange('cancelled'),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => onStatusChange('completed'),
            child: const Text('Complete'),
          ),
        ],
      );
    } else if (appointment.status.toLowerCase() == 'cancelled' &&
        appointment.dateTime.isAfter(DateTime.now())) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () => onStatusChange('scheduled'),
            child: const Text('Reschedule'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
