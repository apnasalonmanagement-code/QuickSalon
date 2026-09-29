import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/service_model.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';
import '../booking_controller.dart';
import '../widgets/service_selection_card.dart';

class BookingServicesScreen extends StatefulWidget {
  const BookingServicesScreen({super.key});

  @override
  State<BookingServicesScreen> createState() => _BookingServicesScreenState();
}

class _BookingServicesScreenState extends State<BookingServicesScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      Future.microtask(() => context.read<BookingController>().loadServices());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingController>(
      builder: (context, controller, _) {
        if (controller.isLoadingServices) {
          return const LoadingWidget(message: 'Loading active services...');
        }
        if (controller.servicesErrorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    controller.servicesErrorMessage!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: controller.loadServices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        if (controller.availableServices.isEmpty) {
          return const EmptyState(
            icon: Icons.content_cut_outlined,
            title: 'No active services available',
            message: 'This salon does not currently have bookable services.',
          );
        }

        final grouped = controller.servicesByCategory;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Text(
              '🌸 Select services',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text('You can select more than one service. ✨'),
            const SizedBox(height: 14),
            if (controller.selectedServices.isNotEmpty)
              _SelectionSummary(controller: controller),
            if (controller.selectedServices.isNotEmpty) const SizedBox(height: 18),
            ...grouped.entries.expand((entry) => [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ServiceSelectionCard(
                        service: service,
                        selected: controller.isSelected(service),
                        onChanged: (_) => controller.toggleService(service),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ]),
          ],
        );
      },
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  const _SelectionSummary({required this.controller});
  final BookingController controller;

  @override
  Widget build(BuildContext context) {
    final requiresRequest = controller.requiresRequestApproval;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: requiresRequest
          ? Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.7)
          : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌸 ${controller.selectedServices.length} service(s) selected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text('⏱️ Duration: ${controller.totalDurationMinutes} min'),
                Text('💰 Total: ₹${controller.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  requiresRequest ? Icons.pending_actions : Icons.check_circle_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requiresRequest
                        ? 'At least one selected service requires salon approval. This information will be carried to the final booking step.'
                        : 'All selected services are marked for direct booking. Final status still follows the existing database booking rules.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}