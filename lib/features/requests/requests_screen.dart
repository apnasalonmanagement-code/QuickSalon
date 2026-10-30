import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'requests_controller.dart';
import 'widgets/request_card.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ChangeNotifierProvider(
      create: (_) =>
          RequestsController()
            ..initialize(),
      child:
          const _RequestsView(),
    );
  }
}

class _RequestsView
    extends StatelessWidget {
  const _RequestsView();

  // ============================================================
  // INSTRUCTION DIALOG
  // ============================================================

  Future<String?> _instructionDialog(
    BuildContext context, {
    required String title,
    required String actionText,
    required Color primaryColor,
  }) async {
    final controller =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller:
                controller,
            maxLines: 4,
            maxLength: 250,
            autofocus: true,
            decoration:
                InputDecoration(
              labelText:
                  'Shop instruction',
              hintText:
                  'Optional message / instruction',
              border:
                  const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () =>
                      Navigator.of(
                        dialogContext,
                      ).pop(),
              child:
                  const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
              onPressed:
                  () =>
                      Navigator.of(
                        dialogContext,
                      ).pop(
                        controller
                            .text
                            .trim(),
                      ),
              child:
                  Text(
                actionText,
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  // ============================================================
  // CONFIRM DIALOG
  // ============================================================

  Future<void> _confirmRequest(
    BuildContext context,
    RequestsController controller,
    String appointmentId,
    Color primaryColor,
  ) async {
    final instruction =
        await _instructionDialog(
      context,
      title:
          'Confirm Request',
      actionText:
          'Confirm',
      primaryColor: primaryColor,
    );

    if (instruction ==
        null) {
      return;
    }

    final success =
        await controller.confirmRequest(
      appointmentId,
      shopInstruction:
          instruction,
    );

    if (!context.mounted) {
      return;
    }

    if (!success) {
      _showError(
        context,
        controller.errorMessage ??
            'Unable to confirm request.',
      );
    }
  }

  // ============================================================
  // REJECT DIALOG
  // ============================================================

  Future<void> _rejectRequest(
    BuildContext context,
    RequestsController controller,
    String appointmentId,
    Color primaryColor,
  ) async {
    final instruction =
        await _instructionDialog(
      context,
      title:
          'Reject Request',
      actionText:
          'Reject',
      primaryColor: primaryColor,
    );

    if (instruction ==
        null) {
      return;
    }

    final success =
        await controller.rejectRequest(
      appointmentId,
      shopInstruction:
          instruction,
    );

    if (!context.mounted) {
      return;
    }

    if (!success) {
      _showError(
        context,
        controller.errorMessage ??
            'Unable to reject request.',
      );
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh(
    RequestsController controller,
  ) async {
    await controller.loadRequests();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Consumer<
        RequestsController>(
      builder: (
        context,
        controller,
        _,
      ) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
          appBar: AppBar(
            title:
                const Text(
              'Requests',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Pending Requests'),
                Tab(text: 'Rejected Appointments'),
              ],
            ),
            actions: [
              IconButton(
                tooltip:
                    'Refresh',
                onPressed:
                    controller.isLoading
                        ? null
                        : () =>
                            controller
                                .loadRequests(),
                icon:
                    const Icon(
                  Icons.refresh,
                ),
              ),
            ],
          ),
          body: TabBarView(
            children: [
              _buildBody(context, controller, primaryColor),
              _buildClosedBody(context, controller, primaryColor),
            ],
          ),
        ));
      },
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildClosedBody(
    BuildContext context,
    RequestsController controller,
    Color primaryColor,
  ) {
    final items = controller.closedAppointments;
    if (controller.isLoading && items.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }
    if (controller.errorMessage != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(controller.errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: () => _refresh(controller),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Center(child: Text('No rejected or cancelled appointments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () => _refresh(controller),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final status = item['status']?.toString().toLowerCase() ?? '';
          final isCancelled = status == 'cancelled';
          final dateValue = item['booking_date']?.toString() ?? '-';
          final timeValue = item['start_time']?.toString() ?? '-';
          final timeParts = timeValue.split(':');
          String timeLabel = timeValue;
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            if (hour != null && minute != null) {
              timeLabel = '${hour % 12 == 0 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
            }
          }
          final rawServices = item['_services'];
          final services = rawServices is List
              ? rawServices.map((service) => service is Map ? (service['service_name_snapshot'] ?? service['name'] ?? 'Service').toString() : service.toString()).join(', ')
              : 'Services';
          final price = item['total_price']?.toString() ?? '0';
          final instruction = item['shop_instruction']?.toString().trim() ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(item['_customer_name']?.toString() ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(isCancelled ? 'CANCELLED' : 'REJECTED', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text('Date: $dateValue  •  Time: $timeLabel'),
                  const SizedBox(height: 6),
                  Text('Services: $services'),
                  const SizedBox(height: 6),
                  Text('Amount: ₹$price', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (instruction.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                      child: Text('Message: $instruction'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RequestsController controller,
    Color primaryColor,
  ) {
    // ==========================================================
    // INITIAL LOADING
    // ==========================================================

    if (controller.isLoading &&
        controller.requests.isEmpty) {
      return Center(
        child:
            CircularProgressIndicator(color: primaryColor),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (controller.errorMessage !=
            null &&
        controller.requests.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Colors.redAccent,
              ),
              const SizedBox(
                height: 12,
              ),
              Text(
                controller
                    .errorMessage!,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
                onPressed:
                    () =>
                        controller
                            .loadRequests(),
                child:
                    const Text(
                  'TRY AGAIN',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (controller.requests.isEmpty) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: () =>
            _refresh(
          controller,
        ),
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(
              height: 140,
            ),
            Icon(
              Icons.inbox_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(
              height: 20,
            ),
            const Center(
              child: Text(
                'No pending requests',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Center(
              child: Text(
                'New booking requests will appear here.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // REQUEST LIST
    // ==========================================================

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: () =>
          _refresh(
        controller,
      ),
      child: ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          16,
        ),
        itemCount:
            controller
                .requests
                .length,
        itemBuilder:
            (
          context,
          index,
        ) {
          final request =
              controller.requests[
                  index];

          final appointmentId =
              request['id']
                  ?.toString();

          // ====================================================
          // INVALID REQUEST
          // ====================================================

          if (appointmentId ==
              null) {
            return const SizedBox
                .shrink();
          }

          // ====================================================
          // REQUEST CARD
          // ====================================================

          return RequestCard(
            request:
                request,
            isProcessing:
                controller
                    .isActionLoading,

            // ==================================================
            // CONFIRM
            // ==================================================

            onConfirm:
                (
              instruction,
            ) async {
              final success =
                  await controller
                      .confirmRequest(
                appointmentId,
                shopInstruction:
                    instruction,
              );

              if (!success &&
                  context.mounted) {
                _showError(
                  context,
                  controller
                          .errorMessage ??
                      'Unable to confirm request.',
                );
              }
            },

            // ==================================================
            // REJECT
            // ==================================================

            onReject:
                (
              instruction,
            ) async {
              final success =
                  await controller
                      .rejectRequest(
                appointmentId,
                shopInstruction:
                    instruction,
              );

              if (!success &&
                  context.mounted) {
                _showError(
                  context,
                  controller
                          .errorMessage ??
                      'Unable to reject request.',
                );
              }
            },

            // ==================================================
            // SAVE INSTRUCTION
            // ==================================================

            onSaveInstruction:
                (
              instruction,
            ) async {
              final success =
                  await controller
                      .updateInstruction(
                appointmentId:
                    appointmentId,
                instruction:
                    instruction,
              );

              if (!success &&
                  context.mounted) {
                _showError(
                  context,
                  controller
                          .errorMessage ??
                      'Unable to save instruction.',
                );
              }
            },
          );
        },
      ),
    );
  }
}


