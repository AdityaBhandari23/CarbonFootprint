import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'log_activity_screen.dart';
import 'history_screen.dart';

/// Main screen with bottom navigation for the three primary screens
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  // List of screens for bottom navigation
  final List<Widget> _screens = [
    const DashboardScreen(),
    const LogActivityScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey[600],
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
            tooltip: 'View your carbon footprint summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Log Activity',
            tooltip: 'Add new carbon footprint activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
            tooltip: 'View your activity history',
          ),
        ],
      ),
    );
  }
} 