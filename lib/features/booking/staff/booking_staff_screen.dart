import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';
import '../booking_controller.dart';
import '../widgets/staff_selection_card.dart';

class BookingStaffScreen extends StatefulWidget {
  const BookingStaffScreen({super.key});

  @override
  State<BookingStaffScreen> createState() => _BookingStaffScreenState();
}

class _BookingStaffScreenState extends State<BookingStaffScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      Future.microtask(() {
        if (mounted) {
          context.read<BookingController>().loadStaff();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingController>(
      builder: (context, controller, _) {
        if (controller.isLoadingStaff) {
          return const LoadingWidget(message: 'Loading available staff...');
        }

        if (controller.staffErrorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    controller.staffErrorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: controller.loadStaff,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.availableStaff.isEmpty) {
          return const EmptyState(
            icon: Icons.person_off_outlined,
            title: 'No active staff available',
            message: 'This salon does not currently have an active staff member for booking.',
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadStaff,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
                '🌸 Select staff',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose one staff member. The existing availability engine will validate the selected staff and time in the next step. ✨',
              ),
              const SizedBox(height: 16),
              ...controller.availableStaff.map(
                (staff) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StaffSelectionCard(
                    staff: staff,
                    selected: controller.selectedStaff?.id == staff.id,
                    onTap: () => controller.selectStaff(staff),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}