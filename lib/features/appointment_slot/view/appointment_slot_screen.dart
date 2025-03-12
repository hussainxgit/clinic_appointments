import 'package:clinic_appointments/features/appointment_slot/view/slot_list_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../shared/services/clinic_service.dart';
import '../../../shared/utilities/utility.dart';
import '../../doctor/models/doctor.dart';
import '../models/appointment_slot.dart';

import 'appointment_slot_patients_screen.dart';
import 'create_appointment_slot_dialog.dart';
import 'slot_filter_sheet.dart';

class AppointmentSlotScreen extends StatefulWidget {
  const AppointmentSlotScreen({super.key});

  @override
  State<AppointmentSlotScreen> createState() => _AppointmentSlotScreenState();
}

class _AppointmentSlotScreenState extends State<AppointmentSlotScreen> {
  // Calendar state
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  // Filter state
  String? _selectedDoctorId;
  bool _showFullyBooked = true;
  bool _showEmptyOnly = false;
  bool _showUpcomingOnly = true;
  String _sortBy = 'date'; // 'date', 'doctor', 'capacity'

  @override
  Widget build(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context);
    final filteredSlots = _getFilteredSlots(clinicService);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(filteredSlots),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSlotDialog(context),
        label: const Text('New Slot'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Appointment Slots',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'Filter slots',
          onPressed: () => _showFilterSheet(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Sort slots',
          onSelected: (value) {
            setState(() {
              _sortBy = value;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'date',
              child: Text('Sort by Date'),
            ),
            const PopupMenuItem(
              value: 'doctor',
              child: Text('Sort by Doctor'),
            ),
            const PopupMenuItem(
              value: 'capacity',
              child: Text('Sort by Available Capacity'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> filteredSlots) {
    return CustomScrollView(
      slivers: [
        // Calendar Section
        SliverToBoxAdapter(
          child: _buildCalendar(),
        ),

        // Header and count
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Text(
                  'Available Slots (${filteredSlots.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // Active filters indicator
                if (_hasActiveFilters())
                  Chip(
                    label: const Text('Filters Active'),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    onDeleted: _clearFilters,
                  ),
              ],
            ),
          ),
        ),

        // Slots List
        filteredSlots.isEmpty
            ? SliverFillRemaining(
                child: _buildEmptyState(),
              )
            : SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final slot =
                          filteredSlots[index]['slot'] as AppointmentSlot;
                      final doctor = filteredSlots[index]['doctor'] as Doctor;

                      return SlotListItem(
                        slot: slot,
                        doctor: doctor,
                        onEdit: () => _editSlot(context, slot),
                        onDelete: () => _bookSlot(context, slot, doctor),
                        onViewDetails: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => AppointmentSlotPatientsScreen(
                                     slot: slot,
                                    ))),
                      );
                    },
                    childCount: filteredSlots.length,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          calendarFormat: _calendarFormat,
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          eventLoader: (day) {
            // This can be used to show dots under dates with slots
            final clinicService =
                Provider.of<ClinicService>(context, listen: false);
            final slots = clinicService.getSlotsByDate(date: day);
            return slots;
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
          ),
          headerStyle: HeaderStyle(
            formatButtonDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            formatButtonTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            titleCentered: true,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No appointment slots available',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _hasActiveFilters()
                ? 'Try changing your filters or select another date'
                : 'Select another date or create a new slot',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          if (_hasActiveFilters())
            FilledButton.tonal(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final doctors = clinicService.getDoctors();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SlotFilterSheet(
        doctors: doctors,
        selectedDoctorId: _selectedDoctorId,
        showFullyBooked: _showFullyBooked,
        showEmptyOnly: _showEmptyOnly,
        showUpcomingOnly: _showUpcomingOnly,
        onApply: (doctorId, fullyBooked, emptyOnly, upcomingOnly) {
          setState(() {
            _selectedDoctorId = doctorId;
            _showFullyBooked = fullyBooked;
            _showEmptyOnly = emptyOnly;
            _showUpcomingOnly = upcomingOnly;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showCreateSlotDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateAppointmentSlot(),
    );
  }

  void _editSlot(BuildContext context, AppointmentSlot slot) {
    // Implement edit slot functionality
    showDialog(
      context: context,
      builder: (context) => EditAppointmentSlot(initialSlot: slot),
    );
  }

  void _bookSlot(BuildContext context, AppointmentSlot slot, Doctor doctor) {
    // Implement book slot functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Creating appointment with ${doctor.name}')),
    );
    // Navigate to appointment creation screen with pre-filled slot and doctor
  }

  List<Map<String, dynamic>> _getFilteredSlots(ClinicService clinicService) {
    // Get slots based on selected date
    var slots = clinicService.getCombinedSlotsWithDoctors(date: _selectedDay);

    // Apply doctor filter
    if (_selectedDoctorId != null) {
      slots = slots
          .where((item) => (item['doctor'] as Doctor).id == _selectedDoctorId)
          .toList();
    }

    // Apply capacity filters
    if (!_showFullyBooked) {
      slots = slots
          .where((item) => !(item['slot'] as AppointmentSlot).isFullyBooked)
          .toList();
    }

    if (_showEmptyOnly) {
      slots = slots
          .where(
              (item) => (item['slot'] as AppointmentSlot).bookedPatients == 0)
          .toList();
    }

    // Apply date filters
    if (_showUpcomingOnly) {
      final now = DateTime.now();
      slots = slots
          .where((item) =>
              (item['slot'] as AppointmentSlot).date.isSameDayOrAfter(now))
          .toList();
    }

    // Sort based on selected criteria
    slots.sort((a, b) {
      final slotA = a['slot'] as AppointmentSlot;
      final slotB = b['slot'] as AppointmentSlot;
      final doctorA = a['doctor'] as Doctor;
      final doctorB = b['doctor'] as Doctor;

      switch (_sortBy) {
        case 'date':
          return slotA.date.compareTo(slotB.date);
        case 'doctor':
          return doctorA.name.compareTo(doctorB.name);
        case 'capacity':
          final availableA = slotA.maxPatients - slotA.bookedPatients;
          final availableB = slotB.maxPatients - slotB.bookedPatients;
          return availableB.compareTo(availableA); // Descending order
        default:
          return 0;
      }
    });

    return slots;
  }

  bool _hasActiveFilters() {
    return _selectedDoctorId != null ||
        !_showFullyBooked ||
        _showEmptyOnly ||
        !_showUpcomingOnly;
  }

  void _clearFilters() {
    setState(() {
      _selectedDoctorId = null;
      _showFullyBooked = true;
      _showEmptyOnly = false;
      _showUpcomingOnly = true;
    });
  }
}

// Make sure to include EditAppointmentSlot class or import it
