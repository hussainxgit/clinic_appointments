import 'package:flutter/material.dart';
import '../../main.dart';
import 'search_bar_widget.dart';
import 'add_appointment_button.dart';
import 'account_avatar_widget.dart';

class NavigationScaffold extends StatefulWidget {
  final List<TabItem> tabs;

  const NavigationScaffold({super.key, required this.tabs});

  @override
  State<NavigationScaffold> createState() => _NavigationScaffoldState();
}

class _NavigationScaffoldState extends State<NavigationScaffold> {
  int _selectedIndex = 0;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _navigatorKeys = List.generate(
        widget.tabs.length, (index) => GlobalKey<NavigatorState>());
  }

  void _onDestinationSelected(int index) {
    if (_selectedIndex != index) {
      _navigatorKeys[_selectedIndex]
          .currentState
          ?.popUntil((route) => route.isFirst);
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColorDark,
        title: Text(
          'Eye Clinic',
          style: TextStyle(color: Colors.white),
        ),
        elevation: 0.3,
        actions: [
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: SearchBarWidget()),
          AddAppointmentButton(),
          AccountAvatarWidget(),
        ],
      ),
      body: Row(
        children: [
          if (isWide) _buildNavigationRail(),
          if (isWide) const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: widget.tabs.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Navigator(
                    key: _navigatorKeys[entry.key],
                    onGenerateRoute: (settings) => MaterialPageRoute(
                      builder: (context) => entry.value.screen,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: widget.tabs.map((tab) {
                return NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.title,
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      extended: true,
      minExtendedWidth: 180,
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      labelType: NavigationRailLabelType.none,
      destinations: widget.tabs.map((tab) {
        return NavigationRailDestination(
          icon: Icon(tab.icon),
          selectedIcon: Icon(tab.selectedIcon),
          label: Text(tab.title),
        );
      }).toList(),
    );
  }
}

class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Clinic',
        style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
