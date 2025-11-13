import 'package:flutter/material.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../dzikir/presentation/zikir_counter_screen.dart';
import '../../prayer_circles/presentation/prayer_circles_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    ZikirCounterScreen(),
    PrayerCirclesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            selectedIcon: Icon(Icons.bubble_chart),
            label: 'Tasbih',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Lingkaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
