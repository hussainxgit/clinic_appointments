import 'package:flutter/material.dart';
import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'dashboard_appointments_list.dart';
import 'dashboard_slots_list.dart';
import 'dashboard_patients_list.dart';

class DashboardTabSection extends StatefulWidget {
  const DashboardTabSection({super.key});

  @override
  State<DashboardTabSection> createState() => _DashboardTabSectionState();
}

class _DashboardTabSectionState extends State<DashboardTabSection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = context.isSmallScreen;

    return Column(
      children: [
        _buildTabBar(context),
        const SizedBox(height: 16),
        _buildDateSelector(context),
        SizedBox(
          height: isSmall ? 350 : 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              DashboardAppointmentsList(selectedDate: _selectedDate),
              DashboardSlotsList(selectedDate: _selectedDate),
              const DashboardPatientsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: constraints.maxWidth < 450 ? 'Appts' : 'Appointments'),
            const Tab(text: 'Slots'),
            const Tab(text: 'Patients'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontSize: constraints.maxWidth < 500 ? 14 : 16),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDateSelector(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 450;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate.dateOnly(),
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: isSmall ? 16 : 18),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, size: isSmall ? 18 : 20),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.subtract(const Duration(days: 1))),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, size: isSmall ? 22 : 24),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward_ios, size: isSmall ? 18 : 20),
                  onPressed: () => setState(() => _selectedDate =
                      _selectedDate.add(const Duration(days: 1))),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
