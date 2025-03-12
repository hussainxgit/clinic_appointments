import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/clinic_service.dart';
import 'appointments_grouped_view.dart';
import 'search_appointment_sheet.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  String? _selectedDoctorId;
  String? _selectedStatus;
  String? _selectedPaymentStatus;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(const Duration(days: 7)),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final clinicService = Provider.of<ClinicService>(context);

    final dateRangeText = '${_dateRange.start.dateOnly()} - ${_dateRange.end.dateOnly()}';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchSheet(context),
            tooltip: 'Search appointments',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter appointments',
            onPressed: () => _showFilterDialog(context, clinicService),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Date range',
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range display
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Text(
                    dateRangeText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Change'),
                    onPressed: () => _selectDateRange(context),
                  ),
                ],
              ),
            ),
          ),
          
          // Active filters display
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildActiveFiltersChip(context, clinicService),
            ),
          
          // Appointments view
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AppointmentsGroupedView(
                dateRange: _dateRange,
                doctorId: _selectedDoctorId,
                status: _selectedStatus,
                paymentStatus: _selectedPaymentStatus,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text("New Appointment"),
        onPressed: () => _showCreateAppointmentSheet(context),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedDoctorId != null || 
           _selectedStatus != null || 
           _selectedPaymentStatus != null;
  }

  Widget _buildActiveFiltersChip(BuildContext context, ClinicService clinicService) {
    final chips = <Widget>[];
    
    if (_selectedDoctorId != null) {
      final doctor = clinicService.getDoctors().firstWhere(
        (d) => d.id == _selectedDoctorId,
        orElse: () => clinicService.getDoctors().first,
      );
      
      chips.add(_buildFilterChip(
        label: 'Doctor: ${doctor.name}',
        onDeleted: () {
          setState(() {
            _selectedDoctorId = null;
          });
        },
      ));
    }
    
    if (_selectedStatus != null) {
      chips.add(_buildFilterChip(
        label: 'Status: $_selectedStatus',
        onDeleted: () {
          setState(() {
            _selectedStatus = null;
          });
        },
      ));
    }
    
    if (_selectedPaymentStatus != null) {
      chips.add(_buildFilterChip(
        label: 'Payment: $_selectedPaymentStatus',
        onDeleted: () {
          setState(() {
            _selectedPaymentStatus = null;
          });
        },
      ));
    }
    
    if (chips.isNotEmpty) {
      chips.add(
        TextButton(
          onPressed: () {
            setState(() {
              _selectedDoctorId = null;
              _selectedStatus = null;
              _selectedPaymentStatus = null;
            });
          },
          child: const Text('Clear All'),
        ),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips,
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDeleted}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDeleted,
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ClinicService clinicService) {
    showDialog(
      context: context,
      builder: (context) {
        String? tempDoctorId = _selectedDoctorId;
        String? tempStatus = _selectedStatus;
        String? tempPaymentStatus = _selectedPaymentStatus;
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Appointments'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        hintText: 'Select Doctor',
                      ),
                      value: tempDoctorId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Doctors'),
                        ),
                        ...clinicService.getDoctors().map((doctor) {
                          return DropdownMenuItem<String>(
                            value: doctor.id,
                            child: Text(doctor.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempDoctorId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        hintText: 'Select Status',
                      ),
                      value: tempStatus,
                      items: const [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Statuses'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'scheduled',
                          child: Text('Scheduled'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        hintText: 'Select Payment Status',
                      ),
                      value: tempPaymentStatus,
                      items: const [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Payment Statuses'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'paid',
                          child: Text('Paid'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'unpaid',
                          child: Text('Unpaid'),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          tempPaymentStatus = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDoctorId = tempDoctorId;
                      _selectedStatus = tempStatus;
                      _selectedPaymentStatus = tempPaymentStatus;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _selectDateRange(BuildContext context) async {
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        _dateRange = newDateRange;
      });
    }
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const SearchAppointmentSheet(),
    );
  }

  void _showCreateAppointmentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CreateAppointmentSheet(selectedDate: _dateRange.start),
    );
  }
}

class CreateAppointmentSheet extends StatelessWidget {
  final DateTime selectedDate;

  const CreateAppointmentSheet({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'New Appointment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selected Date: ${selectedDate.dateOnly()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // Form fields would go here
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Implement appointment creation
                Navigator.pop(context);
              },
              child: const Text('Create Appointment'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}