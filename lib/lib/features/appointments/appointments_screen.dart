import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../urgent_booking/date/urgent_date_screen.dart';
import 'appointments_controller.dart';
import 'widgets/appointment_card.dart';

class AppointmentsScreen
    extends StatelessWidget {
  const AppointmentsScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ChangeNotifierProvider(
      create: (_) =>
          AppointmentsController()
            ..initialize(),
      child:
          const _AppointmentsView(),
    );
  }
}

class _AppointmentsView
    extends StatelessWidget {
  const _AppointmentsView();

  // ============================================================
  // DATE LABEL
  // ============================================================

  String _dateLabel(
    DateTime date,
  ) {
    final today =
        DateTime.now();

    final todayOnly =
        DateTime(
      today.year,
      today.month,
      today.day,
    );

    final difference =
        date
            .difference(
              todayOnly,
            )
            .inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Tomorrow';
    }

    if (difference == 2) {
      return 'Day After Tomorrow';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // ============================================================
  // CONFIRM
  // ============================================================

  Future<void> _confirm(
    BuildContext context,
    AppointmentsController controller,
    Map<String, dynamic> appointment,
  ) async {
    final instruction =
        await _instructionDialog(
      context,
      title:
          'Confirm Appointment',
      actionText:
          'Confirm',
      initialValue:
          appointment[
                  'shop_instruction']
              ?.toString() ??
              '',
    );

    if (instruction == null) {
      return;
    }

    final success =
        await controller.confirm(
      appointment,
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
            'Unable to confirm appointment.',
      );
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _reject(
    BuildContext context,
    AppointmentsController controller,
    Map<String, dynamic> appointment,
  ) async {
    final instruction =
        await _instructionDialog(
      context,
      title:
          'Reject Appointment',
      actionText:
          'Reject',
      initialValue:
          appointment[
                  'shop_instruction']
              ?.toString() ??
              '',
    );

    if (instruction == null) {
      return;
    }

    final success =
        await controller.reject(
      appointment,
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
            'Unable to reject appointment.',
      );
    }
  }

  // ============================================================
  // CANCEL
  // ============================================================

  Future<void> _cancel(
    BuildContext context,
    AppointmentsController controller,
    Map<String, dynamic> appointment,
  ) async {
    final instruction =
        await _instructionDialog(
      context,
      title:
          'Cancel Appointment',
      actionText:
          'Cancel Appointment',
      initialValue:
          appointment[
                  'shop_instruction']
              ?.toString() ??
              '',
    );

    if (instruction == null) {
      return;
    }

    final success =
        await controller.cancel(
      appointment,
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
            'Unable to cancel appointment.',
      );
    }
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<void> _complete(
    BuildContext context,
    AppointmentsController controller,
    Map<String, dynamic> appointment,
  ) async {
    final instruction =
        await _instructionDialog(
      context,
      title:
          'Complete Appointment',
      actionText:
          'Complete',
      initialValue:
          appointment[
                  'shop_instruction']
              ?.toString() ??
              '',
    );

    if (instruction == null) {
      return;
    }

    final success =
        await controller.complete(
      appointment,
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
            'Unable to complete appointment.',
      );
    }
  }

  // ============================================================
  // INSTRUCTION DIALOG
  // ============================================================

  Future<String?> _instructionDialog(
    BuildContext context, {
    required String title,
    required String actionText,
    String initialValue = '',
  }) async {
    final controller =
        TextEditingController(
      text: initialValue,
    );

    final result =
        await showDialog<String?>(
      context: context,
      builder:
          (dialogContext) {
        return AlertDialog(
          title:
              Text(title),
          content:
              TextField(
            controller:
                controller,
            maxLines:
                4,
            maxLength:
                250,
            textCapitalization:
                TextCapitalization
                    .sentences,
            decoration:
                const InputDecoration(
              labelText:
                  'Shop instruction (optional)',
              hintText:
                  'Add an instruction for the customer...',
              border:
                  OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
              ),
              child:
                  const Text(
                'BACK',
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                dialogContext,
                controller.text
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
        content:
            Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Consumer<
        AppointmentsController>(
      builder: (
        context,
        controller,
        _,
      ) {
        return Scaffold(
          appBar: AppBar(
            title:
                const Text(
              'Appointments',
            ),
            actions: [
              IconButton(
                tooltip:
                    'Select Date',
                onPressed:
                    () =>
                        _selectDate(
                  context,
                  controller,
                ),
                icon:
                    const Icon(
                  Icons
                      .calendar_month_outlined,
                ),
              ),
              IconButton(
                tooltip:
                    'Refresh',
                onPressed:
                    controller
                            .isLoading
                        ? null
                        : () =>
                            controller
                                .loadAppointments(),
                icon:
                    const Icon(
                  Icons.refresh,
                ),
              ),
            ],
          ),

          body:
              _buildBody(
            context,
            controller,
          ),
        );
      },
    );
  }

  // ============================================================
  // DATE SELECTOR
  // ============================================================

  Future<void> _selectDate(
    BuildContext context,
    AppointmentsController controller,
  ) async {
    final selected =
        await showDatePicker(
      context: context,
      initialDate:
          controller.selectedDate,
      firstDate:
          DateTime.now().subtract(
        const Duration(
          days: 365,
        ),
      ),
      lastDate:
          DateTime.now().add(
        const Duration(
          days: 365,
        ),
      ),
    );

    if (selected == null) {
      return;
    }

    await controller
        .selectDate(
      selected,
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    BuildContext context,
    AppointmentsController controller,
  ) {
    return Column(
      children: [
        _DateSelector(
          controller:
              controller,
          dateLabel:
              _dateLabel,
        ),

        Expanded(
          child: Stack(
            children: [
              // --------------------------------------------------
              // APPOINTMENT CONTENT
              // --------------------------------------------------

              Positioned.fill(
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    top: 8,
                    bottom: 92,
                  ),
                  child:
                      _buildAppointments(
                    context,
                    controller,
                  ),
                ),
              ),

              // --------------------------------------------------
              // STATIC URGENT BOOKING BUTTON
              // --------------------------------------------------

              Positioned(
                right: 18,
                bottom: 18,
                child:
                    FloatingActionButton
                        .extended(
                  heroTag:
                      'urgent-booking-button',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const UrgentDateScreen(),
                      ),
                    );
                  },
                  icon:
                      const Icon(
                    Icons.flash_on,
                  ),
                  label:
                      const Text(
                    'URGENT BOOKING',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // APPOINTMENTS
  // ============================================================

  Widget _buildAppointments(
    BuildContext context,
    AppointmentsController controller,
  ) {
    if (controller.isLoading &&
        controller.appointments
            .isEmpty) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (controller.errorMessage !=
            null &&
        controller.appointments
            .isEmpty) {
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
                size: 52,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                controller
                    .errorMessage!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(
                height: 16,
              ),

              FilledButton(
                onPressed:
                    () =>
                        controller
                            .loadAppointments(),
                child:
                    const Text(
                  'Try Again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.appointments
        .isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            controller
                .loadAppointments(),
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 140,
            ),
            Icon(
              Icons
                  .calendar_month_outlined,
              size: 70,
            ),
            SizedBox(
              height: 18,
            ),
            Center(
              child: Text(
                'No appointments',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Center(
              child: Text(
                'There are no appointments for this date.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          controller
              .loadAppointments(),
      child:
          ListView.builder(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(
          16,
        ),
        itemCount:
            controller
                .appointments
                .length,
        itemBuilder:
            (context, index) {
          final appointment =
              controller
                  .appointments[index];

          return _AppointmentGroupItem(
            appointment:
                appointment,

            controller:
                controller,

            onConfirm:
                (instruction) async {
              final success =
                  await controller
                      .confirm(
                appointment,
                shopInstruction:
                    instruction,
              );

              if (!success &&
                  context.mounted) {
                _showError(
                  context,
                  controller
                          .errorMessage ??
                      'Unable to confirm appointment.',
                );
              }
            },

            onReject:
                (instruction) async {
              final success =
                  await controller
                      .reject(
                appointment,
                shopInstruction:
                    instruction,
              );

              if (!success &&
                  context.mounted) {
                _showError(
                  context,
                  controller
                          .errorMessage ??
                      'Unable to reject appointment.',
                );
              }
            },

            onCancel:
                (instruction) async {
              final success =
                  await controller
                      .cancel(
                appointment,
                shopInstruction:
                    instruction,
              );

              if (!success &&
                  context.mounted) {
                _showError(
                  context,
                  controller
                          .errorMessage ??
                      'Unable to cancel appointment.',
                );
              }
            },

            onComplete:
                (instruction) async {
              final success =
                  await controller
                      .complete(
                appointment,
                shopInstruction:
                    instruction,
              );

              if (!success &&
                  context.mounted) {
                _showError(
                  context,
                  controller
                          .errorMessage ??
                      'Unable to complete appointment.',
                );
              }
            },

            onSaveInstruction:
                (instruction) async {
              final success =
                  await controller
                      .updateInstruction(
                appointmentId:
                    appointment[
                            'id']
                        .toString(),
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

// ================================================================
// DATE SELECTOR
// ================================================================

class _DateSelector
    extends StatelessWidget {
  const _DateSelector({
    required this.controller,
    required this.dateLabel,
  });

  final AppointmentsController
      controller;

  final String Function(DateTime)
      dateLabel;

  @override
  Widget build(
    BuildContext context,
  ) {
    final today =
        DateTime.now();

    final todayOnly =
        DateTime(
      today.year,
      today.month,
      today.day,
    );

    final dates = [
      todayOnly,
      todayOnly.add(
        const Duration(
          days: 1,
        ),
      ),
      todayOnly.add(
        const Duration(
          days: 2,
        ),
      ),
    ];

    final selected =
        controller.selectedDate;

    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        scrollDirection:
            Axis.horizontal,
        itemCount:
            dates.length + 1,
        separatorBuilder:
            (_, __) =>
                const SizedBox(
          width: 8,
        ),
        itemBuilder:
            (context, index) {
          if (index ==
              dates.length) {
            return OutlinedButton.icon(
              onPressed: () async {
                final date =
                    await showDatePicker(
                  context: context,
                  initialDate:
                      controller
                          .selectedDate,
                  firstDate:
                      DateTime.now()
                          .subtract(
                    const Duration(
                      days: 365,
                    ),
                  ),
                  lastDate:
                      DateTime.now()
                          .add(
                    const Duration(
                      days: 365,
                    ),
                  ),
                );

                if (date != null) {
                  await controller
                      .selectDate(
                    date,
                  );
                }
              },
              icon:
                  const Icon(
                Icons
                    .calendar_month,
                size: 18,
              ),
              label:
                  const Text(
                'Other Date',
              ),
            );
          }

          final date =
              dates[index];

          final isSelected =
              selected.year ==
                      date.year &&
                  selected.month ==
                      date.month &&
                  selected.day ==
                      date.day;

          return ChoiceChip(
            selected:
                isSelected,
            label:
                Text(
              dateLabel(
                date,
              ),
            ),
            onSelected:
                (_) async {
              await controller
                  .selectDate(
                date,
              );
            },
          );
        },
      ),
    );
  }
}

// ================================================================
// GROUPED TIME ITEM
// ================================================================

class _AppointmentGroupItem
    extends StatelessWidget {
  const _AppointmentGroupItem({
    required this.appointment,
    required this.controller,
    required this.onConfirm,
    required this.onReject,
    required this.onCancel,
    required this.onComplete,
    required this.onSaveInstruction,
  });

  final Map<String, dynamic>
      appointment;

  final AppointmentsController
      controller;

  final ValueChanged<String>
      onConfirm;

  final ValueChanged<String>
      onReject;

  final ValueChanged<String>
      onCancel;

  final ValueChanged<String>
      onComplete;

  final ValueChanged<String>
      onSaveInstruction;

  @override
  Widget build(
    BuildContext context,
  ) {
    final start =
        appointment[
                'start_time']
            ?.toString();

    final hour =
        start != null &&
                start.length >= 5
            ? start.substring(
                0,
                5,
              )
            : start ?? '-';

    final status =
        appointment['status']
            ?.toString();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(
            left: 4,
            bottom: 6,
            top: 4,
          ),
          child: Text(
            hour,
            style: Theme.of(
              context,
            )
                .textTheme
                .titleSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),
        ),

        AppointmentCard(
          appointment:
              appointment,

          onConfirm:
              controller.canTransition(
            status ?? '',
            'confirmed',
          )
                  ? onConfirm
                  : null,

          onReject:
              controller.canTransition(
            status ?? '',
            'rejected',
          )
                  ? onReject
                  : null,

          onCancel:
              controller.canTransition(
            status ?? '',
            'cancelled',
          )
                  ? onCancel
                  : null,

          onComplete:
              controller.canTransition(
            status ?? '',
            'completed',
          )
                  ? onComplete
                  : null,
        ),

        const SizedBox(
          height: 12,
        ),
      ],
    );
  }
}