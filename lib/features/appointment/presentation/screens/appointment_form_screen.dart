import 'package:clinic_appointments/features/appointment/domain/entities/appointment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/loading_button.dart';
import '../../../../core/ui/error_display.dart';
import '../../../doctor/presentation/provider/doctor_notifier.dart';
import '../../../patient/domain/entities/patient.dart';
import '../../../patient/presentation/providers/patient_notifier.dart';
import '../../../appointment_slot/domain/entities/appointment_slot.dart';
import '../../../appointment_slot/domain/entities/time_slot.dart';
import '../../../appointment_slot/presentation/providers/appointment_slot_notifier.dart';
import '../providers/appointment_notifier.dart';
import '../../../doctor/domain/entities/doctor.dart';

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final String? patientId;
  final String? doctorId;

  const AppointmentFormScreen({super.key, this.patientId, this.doctorId});

  @override
  ConsumerState<AppointmentFormScreen> createState() =>
      _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  String? _selectedPatientId;
  String? _selectedDoctorId;
  DateTime? _selectedDate;
  AppointmentSlot? _selectedSlot;
  TimeSlot? _selectedTimeSlot;
  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _selectedDoctorId = widget.doctorId;

    // Initialize with today's date
    _selectedDate = DateTime.now();

    // Load data in the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    // If we have a doctor, load their slots
    if (_selectedDoctorId != null) {
      await _loadSlotsForDoctor();
    }
  }

  Future<void> _loadSlotsForDoctor() async {
    if (_selectedDoctorId == null) return;

    // Refresh slots to ensure we have the latest data
    await ref.read(appointmentSlotNotifierProvider.notifier).refreshSlots();
  }

  void _onPatientChanged(String? patientId) {
    setState(() {
      _selectedPatientId = patientId;
    });
  }

  void _onDoctorChanged(String? doctorId) {
    setState(() {
      _selectedDoctorId = doctorId;
      _selectedSlot = null;
      _selectedTimeSlot = null;
    });

    if (doctorId != null) {
      _loadSlotsForDoctor();
    }
  }

  void _onDateChanged(DateTime? date) {
    setState(() {
      _selectedDate = date;
      _selectedSlot = null;
      _selectedTimeSlot = null;
    });
  }

  void _onSlotSelected(AppointmentSlot slot) {
    setState(() {
      _selectedSlot = slot;
      _selectedTimeSlot = null;
    });
  }

  void _onTimeSlotSelected(TimeSlot timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  Future<void> _createAppointment() async {
    if (_selectedPatientId == null) {
      ErrorDisplay.showError(context, "Please select a patient");
      return;
    }

    if (_selectedDoctorId == null) {
      ErrorDisplay.showError(context, "Please select a doctor");
      return;
    }

    if (_selectedSlot == null) {
      ErrorDisplay.showError(context, "Please select an appointment date");
      return;
    }

    if (_selectedTimeSlot == null) {
      ErrorDisplay.showError(context, "Please select an appointment time");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the appointment
      final result = await ref
          .read(appointmentNotifierProvider.notifier)
          .createAppointment(
            Appointment(
              id: '',
              patientId: _selectedPatientId!,
              doctorId: _selectedDoctorId!,
              appointmentSlotId: _selectedSlot!.id,
              timeSlotId: _selectedTimeSlot!.id,
              notes: _notesController.text.trim(),
              dateTime: _selectedDate!,
            ),
          );

      if (result.isSuccess) {
        if (!mounted) return;

        // Show success message
        ErrorDisplay.showSuccess(context, "Appointment created successfully");

        // Navigate back
        Navigator.pop(context);
      } else {
        if (!mounted) return;

        // Show error message
        ErrorDisplay.showError(context, result.error);
      }
    } catch (e) {
      if (!mounted) return;
      ErrorDisplay.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get providers state
    final patientsState = ref.watch(patientNotifierProvider);
    final doctorsState = ref.watch(doctorNotifierProvider);
    final slotsState = ref.watch(appointmentSlotNotifierProvider);

    // Filter slots for the selected doctor and date
    final availableSlots =
        _selectedDoctorId != null && _selectedDate != null
            ? slotsState.slots
                .where(
                  (slot) =>
                      slot.doctorId == _selectedDoctorId &&
                      _isSameDay(slot.date, _selectedDate!),
                )
                .toList()
            : <AppointmentSlot>[];
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Patient Selection
            _buildPatientSelection(patientsState.patients),
            const SizedBox(height: 20),

            // 2. Doctor Selection
            _buildDoctorSelection(doctorsState.doctors),
            const SizedBox(height: 20),

            // 3. Date Selection
            _buildDateSelection(),
            const SizedBox(height: 20),

            // 4. Available slots for selected date
            if (_selectedDoctorId != null && _selectedDate != null)
              _buildAvailableSlotsSection(availableSlots),
            const SizedBox(height: 20),

            // 5. Time Slot Selection
            if (_selectedSlot != null) _buildTimeSlotSelection(_selectedSlot!),
            const SizedBox(height: 20),

            // 6. Notes
            _buildNotesSection(),
            const SizedBox(height: 30),

            // 7. Submit Button
            Center(
              child: LoadingButton(
                text: 'Create Appointment',
                isLoading: _isLoading,
                onPressed: () {
                  if (_canSubmit()) {
                    _createAppointment();
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSelection(List<Patient> patients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Patient', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          value: _selectedPatientId,
          hint: const Text('Select Patient'),
          isExpanded: true,
          items:
              patients
                  .where((p) => p.status == PatientStatus.active)
                  .map(
                    (patient) => DropdownMenuItem(
                      value: patient.id,
                      child: Text(patient.name),
                    ),
                  )
                  .toList(),
          onChanged: _onPatientChanged,
        ),
      ],
    );
  }

  Widget _buildDoctorSelection(List<Doctor> doctors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Doctor', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          value: _selectedDoctorId,
          hint: const Text('Select Doctor'),
          isExpanded: true,
          items:
              doctors
                  .where((d) => d.isAvailable)
                  .map(
                    (doctor) => DropdownMenuItem(
                      value: doctor.id,
                      child: Text("${doctor.name} (${doctor.specialty})"),
                    ),
                  )
                  .toList(),
          onChanged: _onDoctorChanged,
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Date',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );

            if (pickedDate != null) {
              _onDateChanged(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                      : 'Select Date',
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableSlotsSection(List<AppointmentSlot> availableSlots) {
    if (availableSlots.isEmpty) {
      return EmptyState(
        message: 'No available appointment slots for this date.',
        icon: Icons.event_busy,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Appointments',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildSlotList(availableSlots),
      ],
    );
  }

  Widget _buildSlotList(List<AppointmentSlot> slots) {
    // Sort slots by date
    slots.sort((a, b) => a.date.compareTo(b.date));

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        itemBuilder: (context, index) {
          final slot = slots[index];
          final isSelected = _selectedSlot?.id == slot.id;

          return GestureDetector(
            onTap: () => _onSlotSelected(slot),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMMM d').format(slot.date),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE').format(slot.date),
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${slot.availableTimeSlots.length} available times",
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotSelection(AppointmentSlot slot) {
    final availableTimeSlots = slot.availableTimeSlots;

    if (availableTimeSlots.isEmpty) {
      return EmptyState(
        message: 'No available time slots for this date.',
        icon: Icons.access_time,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Time', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              availableTimeSlots.map((timeSlot) {
                final isSelected = _selectedTimeSlot?.id == timeSlot.id;

                // Format the time
                final startHour = timeSlot.startTime.hour.toString().padLeft(
                  2,
                  '0',
                );
                final startMinute = timeSlot.startTime.minute
                    .toString()
                    .padLeft(2, '0');
                final startTime = "$startHour:$startMinute";

                final endHour = timeSlot.endTime.hour.toString().padLeft(
                  2,
                  '0',
                );
                final endMinute = timeSlot.endTime.minute.toString().padLeft(
                  2,
                  '0',
                );
                final endTime = "$endHour:$endMinute";

                return GestureDetector(
                  onTap: () => _onTimeSlotSelected(timeSlot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      "$startTime - $endTime",
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Add appointment notes...',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  bool _canSubmit() {
    return _selectedPatientId != null &&
        _selectedDoctorId != null &&
        _selectedSlot != null &&
        _selectedTimeSlot != null &&
        !_isLoading;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
