import 'package:flutter/material.dart';
import '../../doctor/models/doctor.dart';

class SlotFilterSheet extends StatefulWidget {
  final List<Doctor> doctors;
  final String? selectedDoctorId;
  final bool showFullyBooked;
  final bool showEmptyOnly;
  final bool showUpcomingOnly;
  final Function(String?, bool, bool, bool) onApply;

  const SlotFilterSheet({
    super.key,
    required this.doctors,
    this.selectedDoctorId,
    required this.showFullyBooked,
    required this.showEmptyOnly,
    required this.showUpcomingOnly,
    required this.onApply,
  });

  @override
  State<SlotFilterSheet> createState() => _SlotFilterSheetState();
}

class _SlotFilterSheetState extends State<SlotFilterSheet> {
  late String? _selectedDoctorId;
  late bool _showFullyBooked;
  late bool _showEmptyOnly;
  late bool _showUpcomingOnly;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = widget.selectedDoctorId;
    _showFullyBooked = widget.showFullyBooked;
    _showEmptyOnly = widget.showEmptyOnly;
    _showUpcomingOnly = widget.showUpcomingOnly;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDoctorFilter(context),
                      const SizedBox(height: 16),
                      _buildAvailabilityFilters(context),
                      const SizedBox(height: 16),
                      _buildDateFilters(context),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            'Filter Slots',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Doctor',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintText: 'All Doctors',
          ),
          value: _selectedDoctorId,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Doctors'),
            ),
            ...widget.doctors.map((doctor) {
              return DropdownMenuItem<String>(
                value: doctor.id,
                child: Text(doctor.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _selectedDoctorId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Availability',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Show Fully Booked Slots'),
                subtitle: const Text('Include slots with no available capacity'),
                value: _showFullyBooked,
                onChanged: (value) {
                  setState(() {
                    _showFullyBooked = value;
                    if (value && _showEmptyOnly) {
                      _showEmptyOnly = false;
                    }
                  });
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              SwitchListTile(
                title: const Text('Show Empty Slots Only'),
                subtitle: const Text('Only show slots with no bookings'),
                value: _showEmptyOnly,
                onChanged: (value) {
                  setState(() {
                    _showEmptyOnly = value;
                    if (value && _showFullyBooked) {
                      _showFullyBooked = false;
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SwitchListTile(
            title: const Text('Show Upcoming Slots Only'),
            subtitle: const Text('Hide past appointment slots'),
            value: _showUpcomingOnly,
            onChanged: (value) {
              setState(() {
                _showUpcomingOnly = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedDoctorId = null;
                _showFullyBooked = true;
                _showEmptyOnly = false;
                _showUpcomingOnly = true;
              });
            },
            child: const Text('Reset'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              widget.onApply(
                _selectedDoctorId,
                _showFullyBooked,
                _showEmptyOnly,
                _showUpcomingOnly,
              );
            },
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }
}