import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/clinic_service.dart';
import '../../patient/models/patient.dart';
import '../../doctor/models/doctor.dart';
import '../../appointment_slot/models/appointment_slot.dart';
import '../models/appointment.dart';

class CreateAppointmentModal extends StatefulWidget {
  final Patient? patient;
  final Function(Appointment)? onAppointmentCreated;

  const CreateAppointmentModal(
      {super.key, this.onAppointmentCreated, this.patient});

  @override
  State<CreateAppointmentModal> createState() => _CreateAppointmentModalState();
}

class _CreateAppointmentModalState extends State<CreateAppointmentModal> {
  final _formKey = GlobalKey<FormState>();

  // Search and selection controllers
  final TextEditingController _patientSearchController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selected data
  Patient? _selectedPatient;
  Doctor? _selectedDoctor;
  AppointmentSlot? _selectedSlot;
  DateTime? _selectedDate;

  // UI state
  bool _isSearching = false;
  bool _isLoading = false;
  List<Patient> _searchResults = [];
  List<Doctor> _availableDoctors = [];
  List<AppointmentSlot> _availableSlots = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableDoctors();
    if (widget.patient != null) {
      _selectPatient(widget.patient!);
    }
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadAvailableDoctors() {
    final clinicService = Provider.of<ClinicService>(context, listen: false);
    setState(() {
      _availableDoctors = clinicService.getAvailableDoctorsWithSlots();
    });
  }

  void _searchPatient(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final clinicService = Provider.of<ClinicService>(context, listen: false);
    setState(() {
      _isSearching = true;
      _searchResults = clinicService.searchPatientByQuery(query);
    });
  }

  void _selectPatient(Patient patient) {
    setState(() {
      _selectedPatient = patient;
      _patientSearchController.text = patient.name;
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _selectDoctor(Doctor? doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedSlot = null;
      _selectedDate = null;
      _availableSlots = [];
    });

    if (doctor != null) {
      _loadAvailableSlots();
    }
  }

  void _loadAvailableSlots() {
    if (_selectedDoctor == null) return;

    final clinicService = Provider.of<ClinicService>(context, listen: false);
    setState(() {
      _availableSlots =
          clinicService.getAppointmentSlots(doctorId: _selectedDoctor!.id);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a doctor first')));
      return;
    }

    // Get available dates from slots
    final availableDates = _availableSlots
        .map((slot) => DateTime(slot.date.year, slot.date.month, slot.date.day))
        .toSet()
        .toList();

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No available slots for this doctor')));
      return;
    }

    // Sort dates
    availableDates.sort();

    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = DateTime(now.year + 1, now.month, now.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: availableDates.first,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (DateTime day) {
        // Only allow days that have available slots
        return availableDates.any((availableDate) =>
            availableDate.year == day.year &&
            availableDate.month == day.month &&
            availableDate.day == day.day);
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;

        // Filter slots for the selected date
        final slotsForDate = _availableSlots
            .where((slot) =>
                slot.date.year == picked.year &&
                slot.date.month == picked.month &&
                slot.date.day == picked.day)
            .toList();

        if (slotsForDate.isNotEmpty) {
          _selectedSlot = slotsForDate.first;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPatient == null ||
        _selectedDoctor == null ||
        _selectedSlot == null ||
        _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clinicService = Provider.of<ClinicService>(context, listen: false);

      // Combine date with time from the slot
      final slotDate = _selectedSlot!.date;
      final DateTime appointmentDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        slotDate.hour,
        slotDate.minute,
      );

      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: _selectedPatient!.id,
        doctorId: _selectedDoctor!.id,
        appointmentSlotId: _selectedSlot!.id,
        dateTime: appointmentDateTime,
        status: 'scheduled',
        paymentStatus: 'unpaid',
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final result = await clinicService.createAppointment(appointment);

      if (result.isSuccess) {
        if (widget.onAppointmentCreated != null) {
          widget.onAppointmentCreated!(appointment);
        }
        Navigator.of(context).pop(appointment);
      } else {
        // Service already shows error notification
        // You can add specific error handling here if needed
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Create Appointment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Patient Search
                _buildPatientSearchField(),
                if (_isSearching) _buildSearchResults(),
                const SizedBox(height: 16),

                // Doctor Selection
                _buildDoctorDropdown(),
                const SizedBox(height: 16),

                // Date Selection
                _buildDateSelection(),
                const SizedBox(height: 16),

                // Slot Selection (if date is selected)
                if (_selectedDate != null) _buildSlotSelection(),
                const SizedBox(height: 16),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Submit Button
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Patient', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _patientSearchController,
          decoration: InputDecoration(
            hintText: 'Search patient by name or phone',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: _patientSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _patientSearchController.clear();
                      setState(() {
                        _searchResults = [];
                        _isSearching = false;
                        _selectedPatient = null;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) => _searchPatient(value),
          validator: (value) {
            if (_selectedPatient == null) {
              return 'Please select a patient';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _searchResults.isEmpty
          ? const ListTile(
              title: Text('No results found'),
              leading: Icon(Icons.info),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final patient = _searchResults[index];
                return ListTile(
                  title: Text(patient.name),
                  subtitle: Text(patient.phone),
                  leading: const Icon(Icons.person),
                  onTap: () => _selectPatient(patient),
                );
              },
            ),
    );
  }

  Widget _buildDoctorDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<Doctor>(
          value: _selectedDoctor,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          hint: const Text('Select Doctor'),
          isExpanded: true,
          items: _availableDoctors.map((Doctor doctor) {
            return DropdownMenuItem<Doctor>(
              value: doctor,
              child: Text('${doctor.name} (${doctor.specialty})'),
            );
          }).toList(),
          validator: (value) {
            if (value == null) {
              return 'Please select a doctor';
            }
            return null;
          },
          onChanged: _selectDoctor,
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : _selectedDate!.dateOnly(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotSelection() {
    // Filter slots for the selected date
    final slotsForDate = _availableSlots
        .where((slot) =>
            slot.date.year == _selectedDate!.year &&
            slot.date.month == _selectedDate!.month &&
            slot.date.day == _selectedDate!.day)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Available Slots',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        slotsForDate.isEmpty
            ? const Text('No available slots for selected date')
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slotsForDate.map((slot) {
                  final isSelected = _selectedSlot?.id == slot.id;
                  final timeText = slot.date.dateOnly();
                  final spotsText =
                      '${slot.maxPatients - slot.bookedPatients} spots';

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSlot = slot;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            timeText,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            spotsText,
                            style: TextStyle(
                              color: isSelected ? Colors.white70 : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Create Appointment'),
      ),
    );
  }
}
