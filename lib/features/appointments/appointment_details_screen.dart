import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../app/theme.dart'; // To access current theme type for floral/color styling
import 'appointments_controller.dart';

class AppointmentDetailsScreen
    extends StatefulWidget {
  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
  });

  final AppointmentModel
      appointment;

  @override
  State<
          AppointmentDetailsScreen>
      createState() =>
          _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState
    extends State<
        AppointmentDetailsScreen> {
  late AppointmentModel
      _appointment;

  @override
  void initState() {
    super.initState();

    _appointment =
        widget.appointment;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller =
        context.watch<
            AppointmentsController>();

    final latest =
        controller.appointments
            .where(
      (
        item,
      ) =>
          item.id ==
          _appointment.id,
    ).toList();

    if (latest.isNotEmpty) {
      _appointment =
          latest.first;
    }

    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isSalonTheme,
      builder: (context, isSalon, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Appointment Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          body: ListView(
            padding:
                const EdgeInsets.all(
              16,
            ),

            children: [
              _Header(
                appointment:
                    _appointment,
              ),

              const SizedBox(
                height:
                    16,
              ),

              _Section(
                title:
                    '📅 Booking Information',

                children: [
                  _Row(
                    label:
                        'Date',

                    value:
                        _dateText(
                      _appointment
                          .bookingDate,
                    ),
                  ),

                  _Row(
                    label:
                        'Start time',

                    value:
                        _timeText(
                      _appointment
                          .startTime,
                    ),
                  ),

                  _Row(
                    label:
                        'End time',

                    value:
                        _timeText(
                      _appointment
                          .endTime,
                    ),
                  ),

                  _Row(
                    label:
                        'Duration',

                    value:
                        '${_appointment.totalDurationMinutes} minutes',
                  ),

                  _Row(
                    label:
                        'Total price',

                    value:
                        '₹${_appointment.totalPrice.toStringAsFixed(2)}',
                  ),

                  _Row(
                    label:
                        'Booking type',

                    value:
                        _appointment
                            .bookingType,
                  ),

                  _Row(
                    label:
                        'Status',

                    value:
                        _appointment
                            .status,
                  ),
                ],
              ),

              const SizedBox(
                height:
                    16,
              ),

              _Section(
                title:
                    '🏪 Shop & Staff Details',

                children: [
                  _Row(
                    label:
                        'Shop',

                    value:
                        _appointment
                                .shopName ??
                            'Shop unavailable',
                  ),

                  _Row(
                    label:
                        'Staff',

                    value:
                        _appointment
                                .staffName ??
                            'Not assigned',
                  ),
                ],
              ),

              const SizedBox(
                height:
                    16,
              ),

              _Section(
                title:
                    '💐 Selected Services',

                children:
                    _appointment
                            .services
                            .isEmpty
                        ? const [
                            Padding(
                              padding:
                                  EdgeInsets
                                      .symmetric(
                                vertical:
                                    8,
                              ),

                              child:
                                  Text(
                                'Services unavailable',
                              ),
                            ),
                          ]
                        : _appointment
                            .services
                            .map(
                            (
                              service,
                            ) =>
                                _ServiceTile(
                              service:
                                  service,
                            ),
                          ).toList(),
              ),

              if (controller.canCancel(
                _appointment,
              )) ...[
                const SizedBox(
                  height:
                      24,
                ),

                // Interactive Styled Cancel Button with Elevation and Ripple
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon:
                        controller
                                .isActionLoading
                            ? const SizedBox(
                                width:
                                    18,

                                height:
                                    18,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons
                                    .cancel_outlined,
                              ),

                    label:
                        const Text(
                      'Cancel Appointment',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),

                    onPressed:
                        controller
                                .isActionLoading
                            ? null
                            : _cancel,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancel() async {
    final controller =
        context.read<
            AppointmentsController>();

    final confirmed =
        await showDialog<bool>(
      context:
          context,

      builder:
          (
            context,
          ) =>
              AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text(
          '❌ Cancel appointment?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        content:
            const Text(
          'This action follows the existing appointment status transition rules.',
        ),

        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
              context,
              false,
            ),

            child:
                const Text(
              'Keep',
            ),
          ),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () =>
                Navigator.pop(
              context,
              true,
            ),

            child:
                const Text(
              'Confirm Cancellation',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true ||
        !mounted) {
      return;
    }

    final success =
        await controller
            .cancelAppointment(
      _appointment,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      final latest =
          controller.appointments
              .where(
        (
          item,
        ) =>
            item.id ==
            _appointment.id,
      ).toList();

      if (latest.isNotEmpty) {
        setState(
          () {
            _appointment =
                latest.first;
          },
        );
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Appointment cancelled successfully.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            controller
                    .errorMessage ??
                'Unable to cancel appointment.',
          ),
        ),
      );
    }
  }
}

class _Header
    extends StatelessWidget {
  const _Header({
    required this.appointment,
  });

  final AppointmentModel
      appointment;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Card(
      elevation: 6,
      shadowColor: theme.primaryColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Row(
          children: [
            CircleAvatar(
              radius:
                  30,

              backgroundImage:
                  appointment.shopImageUrl !=
                              null &&
                          appointment
                              .shopImageUrl!
                              .isNotEmpty
                      ? NetworkImage(
                          appointment
                              .shopImageUrl!,
                        )
                      : null,

              child:
                  appointment.shopImageUrl ==
                              null ||
                          appointment
                              .shopImageUrl!
                              .isEmpty
                      ? const Icon(
                          Icons
                              .storefront_outlined,
                        )
                      : null,
            ),

            const SizedBox(
              width:
                  14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    appointment
                            .shopName ??
                        'Shop',

                    style: theme
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(
                    height:
                        4,
                  ),

                  Row(
                    children: [
                      const Text('🌟 Status: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        appointment.status,
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section
    extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
  });

  final String title;

  final List<Widget>
      children;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: theme.primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,

          children: [
            Text(
              title,

              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight
                            .bold,
                    color: theme.primaryColor,
                  ),
            ),

            const Divider(height: 20, thickness: 1.5),

            const SizedBox(
              height:
                  4,
            ),

            ...children,
          ],
        ),
      ),
    );
  }
}

class _Row
    extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
  });

  final String label;

  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical:
            6,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,

        children: [
          SizedBox(
            width:
                120,

            child:
                Text(
              label,

              style:
                  const TextStyle(
                fontWeight:
                    FontWeight
                        .w600,
                color: Colors.black87,
              ),
            ),
          ),

          Expanded(
            child:
                Text(
              value.isEmpty
                  ? '-'
                  : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile
    extends StatelessWidget {
  const _ServiceTile({
    required this.service,
  });

  final Map<String, dynamic>
      service;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    final name =
        service['service_name']
                ?.toString() ??
            service['name']
                ?.toString() ??
            'Service';

    final price =
        service['price'];

    final duration =
        service[
                'duration_minutes'
            ] ??
            service['duration'];

    return ListTile(
      contentPadding:
          EdgeInsets.zero,

      title:
          Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),

      subtitle:
          Text(
        '⏱️ ${duration ?? '-'} min',
        style: TextStyle(color: Colors.grey[700]),
      ),

      trailing:
          Text(
        price == null
            ? ''
            : '₹$price',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.primaryColor,
          fontSize: 15,
        ),
      ),
    );
  }
}

String _dateText(
  DateTime date,
) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _timeText(
  String value,
) {
  final parts =
      value.split(
    ':',
  );

  if (parts.length < 2) {
    return value;
  }

  final hour =
      int.tryParse(
    parts[0],
  );

  final minute =
      int.tryParse(
    parts[1],
  );

  if (hour == null ||
      minute == null) {
    return value;
  }

  final suffix =
      hour >= 12
          ? 'PM'
          : 'AM';

  final displayHour =
      hour % 12 == 0
          ? 12
          : hour % 12;

  return '$displayHour:'
      '${minute.toString().padLeft(2, '0')} '
      '$suffix';
}