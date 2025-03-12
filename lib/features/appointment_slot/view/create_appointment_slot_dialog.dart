import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/clinic_service.dart';
import '../../../shared/utilities/utility.dart';
import '../../doctor/models/doctor.dart';
import '../models/appointment_slot.dart';

class CreateAppointmentSlot extends StatefulWidget {
  const CreateAppointmentSlot({super.key});

  @override
  State<CreateAppointmentSlot> createState() => _CreateAppointmentSlotState();
}

class _CreateAppointmentSlotState extends State<CreateAppointmentSlot> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  Doctor? _selectedDoctor;
  bool _isRecurring = false;
  String _recurringType = 'daily';
  int _numberOfSlots = 1;
  int _maxPatients = 5;

  final List<String> _recurringTypes = ['daily', 'weekly', 'monthly'];

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final doctors = clinicService.getDoctors().where((d) => d.isAvailable).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Appointment Slot'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Doctor Information'),
                const SizedBox(height: 8),
                
                // Doctor selection
                DropdownButtonFormField<Doctor>(
                  decoration: InputDecoration(
                    labelText: 'Select Doctor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: doctors.map((doctor) {
                    return DropdownMenuItem<Doctor>(
                      value: doctor,
                      child: Text(doctor.name),
                    );
                  }).toList(),
                  onChanged: (doctor) => setState(() => _selectedDoctor = doctor),
                  validator: (value) => value == null ? 'Please select a doctor' : null,
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Slot Details'),
                const SizedBox(height: 8),
                
                // Date selection
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Select Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                      errorText: _selectedDate == null ? 'Please select a date' : null,
                    ),
                    child: Text(
                      _selectedDate != null 
                          ? _selectedDate!.dateOnly3() 
                          : 'Tap to select a date',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Max patients
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Maximum Patients',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.group),
                    helperText: 'Maximum number of patients that can be booked in this slot',
                  ),
                  initialValue: _maxPatients.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    _maxPatients = int.tryParse(value) ?? 5;
                  }),
                  validator: (value) {
                    final number = int.tryParse(value ?? '');
                    if (number == null) return 'Please enter a valid number';
                    if (number <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Recurring Options'),
                const SizedBox(height: 8),
                
                // Recurring toggle
                SwitchListTile(
                  title: const Text('Create Recurring Slots'),
                  subtitle: Text(_isRecurring 
                      ? 'Will create multiple slots based on settings below' 
                      : 'Will create a single slot on the selected date'),
                  value: _isRecurring,
                  onChanged: (value) => setState(() => _isRecurring = value),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                
                if (_isRecurring) ...[
                  const SizedBox(height: 16),
                  
                  // Recurring type
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.repeat),
                    ),
                    value: _recurringType,
                    items: _recurringTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type.capitalize()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _recurringType = value!),
                  ),
                  const SizedBox(height: 16),
                  
                  // Number of slots
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Number of Slots to Create',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                      helperText: 'Total number of recurring appointment slots',
                    ),
                    initialValue: _numberOfSlots.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setState(() {
                      _numberOfSlots = int.tryParse(value) ?? 1;
                    }),
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      if (number == null) return 'Please enter a valid number';
                      if (number <= 0) return 'Must be greater than 0';
                      if (number > 52) return 'Maximum 52 slots allowed';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_isRecurring 
                  ? 'Will create $_numberOfSlots slots'
                  : 'Will create 1 slot'),
                FilledButton(
                  onPressed: _submitForm,
                  child: const Text('Create Slot'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a doctor and a date')),
      );
      return;
    }

    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final slots = _generateSlots();
    
    try {
      for (final slot in slots) {
        clinicService.createAppointmentSlot(slot);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully created ${slots.length} appointment slot(s)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating slot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<AppointmentSlot> _generateSlots() {
    final slots = <AppointmentSlot>[];
    final baseDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    for (int i = 0; i < (_isRecurring ? _numberOfSlots : 1); i++) {
      final slotDate = _calculateRecurringDate(baseDate, i);
      
      slots.add(AppointmentSlot(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        doctorId: _selectedDoctor!.id,
        date: slotDate,
        maxPatients: _maxPatients,
        bookedPatients: 0,
      ));
    }

    return slots;
  }

  DateTime _calculateRecurringDate(DateTime baseDate, int index) {
    switch (_recurringType) {
      case 'daily':
        return baseDate.add(Duration(days: index));
      case 'weekly':
        return baseDate.add(Duration(days: index * 7));
      case 'monthly':
        // Add months carefully to handle month boundaries
        final year = baseDate.year + ((baseDate.month + index) ~/ 12);
        final month = (baseDate.month + index) % 12;
        return DateTime(year, month == 0 ? 12 : month, baseDate.day);
      default:
        return baseDate;
    }
  }
}

class EditAppointmentSlot extends StatefulWidget {
  final AppointmentSlot initialSlot;

  const EditAppointmentSlot({
    super.key,
    required this.initialSlot,
  });

  @override
  State<EditAppointmentSlot> createState() => _EditAppointmentSlotState();
}

class _EditAppointmentSlotState extends State<EditAppointmentSlot> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late Doctor? _selectedDoctor;
  late int _maxPatients;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialSlot.date;
    _maxPatients = widget.initialSlot.maxPatients;

    // We'll find the doctor in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Find the doctor using the service
    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final doctors = clinicService.getDoctors();
    _selectedDoctor = doctors.firstWhere(
      (d) => d.id == widget.initialSlot.doctorId,
      orElse: () => doctors.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final doctors = clinicService.getDoctors().where((d) => d.isAvailable).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Appointment Slot'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Doctor Information'),
                const SizedBox(height: 8),
                
                // Doctor selection
                DropdownButtonFormField<Doctor>(
                  decoration: InputDecoration(
                    labelText: 'Doctor',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  value: _selectedDoctor,
                  items: doctors.map((doctor) {
                    return DropdownMenuItem<Doctor>(
                      value: doctor,
                      child: Text(doctor.name),
                    );
                  }).toList(),
                  onChanged: (doctor) => setState(() => _selectedDoctor = doctor),
                  validator: (value) => value == null ? 'Please select a doctor' : null,
                ),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Slot Details'),
                const SizedBox(height: 8),
                
                // Date selection
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDate.dateOnly3(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Max patients
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Maximum Patients',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  initialValue: _maxPatients.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {
                    _maxPatients = int.tryParse(value) ?? 5;
                  }),
                  validator: (value) {
                    final number = int.tryParse(value ?? '');
                    if (number == null) return 'Please enter a valid number';
                    if (number <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                
                // Current bookings info
                const SizedBox(height: 24),
                _buildSectionTitle('Current Status'),
                const SizedBox(height: 8),
                
                Card(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Bookings',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.initialSlot.bookedPatients} patient(s)',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          backgroundColor: _getStatusColor(context),
                          radius: 24,
                          child: Text(
                            '${widget.initialSlot.bookedPatients}/${widget.initialSlot.maxPatients}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _submitForm,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    final slot = widget.initialSlot;
    
    if (slot.isFullyBooked) {
      return Theme.of(context).colorScheme.error;
    } else if (slot.bookedPatients > 0) {
      return Theme.of(context).colorScheme.tertiary;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor')),
      );
      return;
    }

    // Validate max patients isn't less than current bookings
    if (_maxPatients < widget.initialSlot.bookedPatients) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Maximum patients cannot be less than current bookings (${widget.initialSlot.bookedPatients})'
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final clinicService = Provider.of<ClinicService>(context, listen: false);
    
    try {
      final updatedSlot = widget.initialSlot.copyWith(
        doctorId: _selectedDoctor!.id,
        date: _selectedDate,
        maxPatients: _maxPatients,
      );
      
      clinicService.updateAppointmentSlot(updatedSlot);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment slot updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating slot: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}