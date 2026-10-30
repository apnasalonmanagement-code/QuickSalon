import 'package:flutter/material.dart';

import '../appointments/appointments_screen.dart';
import '../requests/requests_screen.dart';
import '../menu/menu_screen.dart';
import '../availability/availability_calendar_screen.dart';
import '../profile/profile_screen.dart';

class ManagementShell extends StatefulWidget {
  const ManagementShell({
    super.key,
    this.initialIndex = 1,
  });

  final int initialIndex;

  @override
  State<ManagementShell> createState() =>
      _ManagementShellState();
}

class _ManagementShellState
    extends State<ManagementShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          // ======================================================
          // 0. APPOINTMENTS
          // ======================================================

          AppointmentsScreen(),

          // ======================================================
          // 1. REQUESTS
          // ======================================================

          RequestsScreen(),

          // ======================================================
          // 2. MENU
          // ======================================================

          MenuScreen(),

          // ======================================================
          // 3. BOOK / AVAILABILITY
          // ======================================================

          AvailabilityCalendarScreen(),

          // ======================================================
          // 4. PROFILE
          // ======================================================

          ProfileScreen(),
        ],
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigationTap,
        destinations: const [
          // ------------------------------------------------------
          // APPOINTMENTS
          // ------------------------------------------------------

          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_outlined,
            ),
            selectedIcon: Icon(
              Icons.calendar_month,
            ),
            label: 'Appointments',
          ),

          // ------------------------------------------------------
          // REQUESTS
          // ------------------------------------------------------

          NavigationDestination(
            icon: Icon(
              Icons.inbox_outlined,
            ),
            selectedIcon: Icon(
              Icons.inbox,
            ),
            label: 'Requests',
          ),

          // ------------------------------------------------------
          // MENU
          // ------------------------------------------------------

          NavigationDestination(
            icon: Icon(
              Icons.menu_book_outlined,
            ),
            selectedIcon: Icon(
              Icons.menu_book,
            ),
            label: 'Menu',
          ),

          // ------------------------------------------------------
          // BOOK
          // ------------------------------------------------------

          NavigationDestination(
            icon: Icon(
              Icons.schedule_outlined,
            ),
            selectedIcon: Icon(
              Icons.schedule,
            ),
            label: 'Book',
          ),

          // ------------------------------------------------------
          // PROFILE
          // ------------------------------------------------------

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}