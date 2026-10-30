import 'package:flutter/material.dart';

import 'availability_calendar_screen.dart';

/// Backwards-compatible entry point for the existing availability structure.
/// Part 7 uses the single availability table and the calendar screen as the
/// management UI; no booking creation is performed here.
class DailyAvailabilityScreen extends StatelessWidget {
  const DailyAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context) => const AvailabilityCalendarScreen();
}
