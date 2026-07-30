import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'crm_screen.dart';
import 'receivables_screen.dart';
import 'system_admin_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    CrmScreen(),
    ReceivablesScreen(),
    SystemAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Sales CRM'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Receivables'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Admin'),
        ],
      ),
    );
  }
}
