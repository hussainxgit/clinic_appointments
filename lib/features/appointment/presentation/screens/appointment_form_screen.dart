// lib/features/appointment/presentation/screens/appointment_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../../../core/ui/widgets/app_card.dart';
import '../../../../core/utils/result.dart';

import '../../../patient/domain/entities/patient.dart';
import '../../../patient/presentation/providers/patient_notifier.dart';
import '../../../doctor/presentation/provider/doctor_notifier.dart';
import '../../../appointment_slot/domain/entities/appointment_slot.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';

import '../../domain/entities/appointment.dart';
import '../providers/appointment_notifier.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  
  const AppointmentFormScreen({super.key, this.isEditing = false});
  
  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Appointment data
  late String _id;
  String? _patientId;
  String? _doctorId;
  String? _appointmentSlotId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _notes = '';
  String _status = 'scheduled';
  String _paymentStatus = 'unpaid';
  
  // For selecting slot
  List<AppointmentSlot> _availableSlots = [];
  AppointmentSlot? _selectedSlot;
  
  @override
  void initState() {
    super.initState();
    _id = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (widget.isEditing) {
      // Get passed arguments from route
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null && args.containsKey('appointment')) {
        final appointment = args['appointment'] as Appointment;
        
        // Initialize with existing appointment data
        _id = appointment.id;
        _patientId = appointment.patientId;
        _doctorId = appointment.doctorId;
        _appointmentSlotId = appointment.appointmentSlotId;
        _selectedDate = appointment.dateTime;
        _selectedTime = TimeOfDay.fromDateTime(appointment.dateTime);
        _notes = appointment.notes ?? '';
        _status = appointment.status;
        _paymentStatus = appointment.paymentStatus;
      }
    } else {
      // Handle appointment creation with pre-selected data if provided
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      
      if (args != null) {
        // Pre-selected doctor and slot
        if (args.containsKey('doctorId')) {
          _doctorId = args['doctorId'] as String;
        }
        
        if (args.containsKey('appointmentSlotId')) {
          _appointmentSlotId = args['appointmentSlotId'] as String;
        }
        
        if (args.containsKey('dateTime')) {
          final dateTime = args['dateTime'] as DateTime;
          _selectedDate = dateTime;
          _selectedTime = TimeOfDay.fromDateTime(dateTime);
        }
        
        if (args.containsKey('patientId')) {
          _patientId = args['patientId'] as String;
        }
      }
    }
    
    // Load available slots based on selected date and doctor
    _loadAvailableSlots();
  }
  
  void _loadAvailableSlots() {
    if (_doctorId != null) {
      // Get slots for this doctor and date
      final slotNotifier = ref.read(appointmentSlotNotifierProvider.notifier);
      _availableSlots = slotNotifier.getSlots(
        doctorId: _doctorId,
        date: _selectedDate,
      ).where((slot) => !slot.isFullyBooked || 
                         (_appointmentSlotId != null && slot.id == _appointmentSlotId))
       .toList();
      
      // Find selected slot if we have an appointment slot ID
      if (_appointmentSlotId != null) {
        _selectedSlot = _availableSlots.firstWhere(
          (slot) => slot.id == _appointmentSlotId,
          orElse: () => _availableSlots.isNotEmpty ? _availableSlots.first : throw Exception('No available slots'),
        );
      } else if (_availableSlots.isNotEmpty) {
        _selectedSlot = _availableSlots.first;
        _appointmentSlotId = _selectedSlot?.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Appointment' : 'New Appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientSelection(),
              const SizedBox(height: 16),
              _buildDoctorSelection(),
              const SizedBox(height: 16),
              _buildDateTimePickers(),
              const SizedBox(height: 16),
              if (_doctorId != null && _availableSlots.isNotEmpty)
                _buildSlotSelection(),
              const SizedBox(height: 16),
              if (widget.isEditing) ...[
                _buildStatusSelection(),
                const SizedBox(height: 16),
                _buildPaymentStatusSelection(),
                const SizedBox(height: 16),
              ],
              _buildNotesField(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  text: widget.isEditing ? 'Update Appointment' : 'Create Appointment',
                  isLoading: _isLoading,
                  onPressed: _saveAppointment,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPatientSelection() {
    final patientState = ref.watch(patientNotifierProvider);
    
    // Filter for active patients only
    final patients = patientState.patients
        .where((p) => p.status == PatientStatus.active)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Patient',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select a patient',
          ),
          value: _patientId,
          items: patients.map((patient) {
            return DropdownMenuItem<String>(
              value: patient.id,
              child: Text(patient.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _patientId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a patient';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildDoctorSelection() {
    final doctorState = ref.watch(doctorNotifierProvider);
    
    // Filter for available doctors only
    final doctors = doctorState.doctors
        .where((d) => d.isAvailable)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Doctor',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select a doctor',
          ),
          value: _doctorId,
          items: doctors.map((doctor) {
            return DropdownMenuItem<String>(
              value: doctor.id,
              child: Text('${doctor.name} (${doctor.specialty})'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _doctorId = value;
              _appointmentSlotId = null;
              _selectedSlot = null;
              // Reload available slots when doctor changes
              _loadAvailableSlots();
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a doctor';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildDateTimePickers() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(_selectedTime.format(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSlotSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Slots',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_availableSlots.isEmpty)
          const Text(
            'No available slots for this doctor on the selected date',
            style: TextStyle(color: Colors.red),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableSlots.length,
              itemBuilder: (context, index) {
                final slot = _availableSlots[index];
                final isSelected = _selectedSlot?.id == slot.id;
                final time = DateFormat('h:mm a').format(slot.date);
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: AppCard(
                    color: isSelected ? Colors.blue.shade100 : null,
                    onTap: () {
                      setState(() {
                        _selectedSlot = slot;
                        _appointmentSlotId = slot.id;
                        _selectedTime = TimeOfDay.fromDateTime(slot.date);
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blue.shade900 : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${slot.bookedPatients}/${slot.maxPatients} booked',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.blue.shade900 : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Colors.blue),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          value: _status,
          items: const [
            DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
            DropdownMenuItem(value: 'completed', child: Text('Completed')),
            DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _status = value;
              });
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildPaymentStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Status',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          value: _paymentStatus,
          items: const [
            DropdownMenuItem(value: 'paid', child: Text('Paid')),
            DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _paymentStatus = value;
              });
            }
          },
        ),
      ],
    );
  }
  
  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _notes,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter any notes about this appointment',
          ),
          maxLines: 3,
          onChanged: (value) {
            _notes = value;
          },
        ),
      ],
    );
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Reload available slots when date changes
        _loadAvailableSlots();
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  DateTime _combineDateAndTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }
  
  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_appointmentSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available appointment slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final appointmentNotifier = ref.read(appointmentNotifierProvider.notifier);
      
      // Create appointment object
      final appointment = Appointment(
        id: _id,
        patientId: _patientId!,
        doctorId: _doctorId!,
        appointmentSlotId: _appointmentSlotId!,
        dateTime: _combineDateAndTime(),
        status: _status,
        paymentStatus: _paymentStatus,
        notes: _notes.isNotEmpty ? _notes : null,
      );
      
      Result<Appointment> result;
      
      if (widget.isEditing) {
        result = await appointmentNotifier.updateAppointment(appointment);
      } else {
        result = await appointmentNotifier.createAppointment(appointment);
      }
      
      setState(() {
        _isLoading = false;
      });
      
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Appointment updated successfully'
                  : 'Appointment created successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        ref.read(navigationServiceProvider).goBack();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}