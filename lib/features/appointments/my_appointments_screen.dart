import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/appointment_model.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';
import '../../app/theme.dart';

import 'appointment_details_screen.dart';
import 'appointments_controller.dart';

class MyAppointmentsScreen
    extends StatelessWidget {
  const MyAppointmentsScreen({
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
          const _MyAppointmentsView(),
    );
  }
}

class _MyAppointmentsView
    extends StatelessWidget {
  const _MyAppointmentsView();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Consumer<
        AppointmentsController>(
      builder:
          (
            context,
            controller,
            _,
          ) {
        return ValueListenableBuilder<bool>(
          valueListenable: AppTheme.isSalonTheme,
          builder: (context, isSalon, child) {
            return Scaffold(
              appBar: AppBar(
                title: const Text(
                  'My Appointments',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Refresh Appointments',
                    onPressed:
                        controller.isLoading
                            ? null
                            : controller
                                .loadAppointments,

                    icon:
                        const Icon(
                      Icons.refresh,
                    ),
                  ),
                ],
              ),

              body: Column(
                children: [
                  _Filters(
                    controller:
                        controller,
                  ),

                  Expanded(
                    child: _Body(
                      controller:
                          controller,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Filters
    extends StatelessWidget {
  const _Filters({
    required this.controller,
  });

  final AppointmentsController
      controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    final primaryColor = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,

      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12,
      ),

      child: Row(
        children:
            AppointmentFilter
                .values
                .map(
          (
            filter,
          ) {
            final selected =
                controller.filter ==
                    filter;

            return Padding(
              padding:
                  const EdgeInsets.only(
                right:
                    10,
              ),

              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: ChoiceChip(
                  label:
                      Text(
                    _label(
                      filter,
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : primaryColor,
                    ),
                  ),

                  selected:
                      selected,
                  selectedColor: primaryColor,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  elevation: selected ? 4 : 0,
                  pressElevation: 6,
                  shadowColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: primaryColor, width: 1.5),
                  ),

                  onSelected: (_) {
                    controller.setFilter(
                      filter,
                    );
                  },
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  String _label(
    AppointmentFilter filter,
  ) {
    switch (filter) {
      case AppointmentFilter
            .upcoming:
        return 'Upcoming';

      case AppointmentFilter
            .pending:
        return 'Pending';

      case AppointmentFilter
            .past:
        return 'Past';

      case AppointmentFilter
            .cancelled:
        return 'Cancelled';
    }
  }
}

class _Body
    extends StatelessWidget {
  const _Body({
    required this.controller,
  });

  final AppointmentsController
      controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (controller.isLoading &&
        controller
            .appointments
            .isEmpty) {
      return const LoadingWidget(
        message:
            'Loading appointments...',
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (controller.errorMessage !=
            null &&
        controller
            .appointments
            .isEmpty) {
      return _ErrorState(
        message:
            controller
                .errorMessage!,

        onRetry:
            controller
                .loadAppointments,
      );
    }

    final appointments =
        controller
            .filteredAppointments;

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (appointments.isEmpty) {
      return EmptyState(
        icon:
            Icons
                .calendar_month_outlined,

        title:
            'No ${_emptyLabel(controller.filter)} appointments',

        message:
            'Appointments in this category will appear here.',
      );
    }

    // ==========================================================
    // LIST
    // ==========================================================

    return RefreshIndicator(
      onRefresh:
          controller
              .loadAppointments,

      child:
          ListView.separated(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24,
        ),

        itemCount:
            appointments.length,

        separatorBuilder:
            (
              _,
              __,
            ) =>
                const SizedBox(
          height:
              14,
        ),

        itemBuilder:
            (
              context,
              index,
            ) {
          final appointment =
              appointments[index];

          return _AppointmentCard(
            appointment:
                appointment,

            onTap: () async {
              await Navigator.of(
                context,
              ).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChangeNotifierProvider
                          .value(
                    value:
                        controller,

                    child:
                        AppointmentDetailsScreen(
                      appointment:
                          appointment,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _emptyLabel(
    AppointmentFilter filter,
  ) {
    switch (filter) {
      case AppointmentFilter
            .upcoming:
        return 'upcoming';

      case AppointmentFilter
            .pending:
        return 'pending';

      case AppointmentFilter
            .past:
        return 'past';

      case AppointmentFilter
            .cancelled:
        return 'cancelled';
    }
  }
}

class _AppointmentCard
    extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
  });

  final AppointmentModel
      appointment;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Card(
      elevation: 5,
      shadowColor: theme.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior:
          Clip.antiAlias,

      child: InkWell(
        onTap:
            onTap,
        splashColor: theme.primaryColor.withOpacity(0.2),
        highlightColor: theme.primaryColor.withOpacity(0.1),

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
              Row(
                children: [
                  _ShopImage(
                    url:
                        appointment
                            .shopImageUrl,
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
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                        ),

                        const SizedBox(
                          height:
                              4,
                        ),

                        Text(
                          'Staff: ${appointment.staffName ?? 'Not assigned'}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),

                  _StatusChip(
                    status:
                        appointment
                            .status,
                  ),
                ],
              ),

              const Divider(height: 20, thickness: 1),

              Text(
                _serviceNames(
                  appointment,
                ),

                maxLines:
                    2,

                overflow:
                    TextOverflow
                        .ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(
                height:
                    10,
              ),

              Row(
                children: [
                  Icon(
                    Icons
                        .calendar_today_outlined,

                    size:
                        16,
                    color: theme.primaryColor,
                  ),

                  const SizedBox(
                    width:
                        6,
                  ),

                  Expanded(
                    child: Text(
                      '${_dateText(appointment.bookingDate)} • '
                      '${_timeText(appointment.startTime)} – '
                      '${_timeText(appointment.endTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                    8,
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '⏱️ ${appointment.totalDurationMinutes} min • ${appointment.bookingType}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),

                  Text(
                    '₹${appointment.totalPrice.toStringAsFixed(2)}',

                    style: theme
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: theme.primaryColor,
                          fontSize: 16,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopImage
    extends StatelessWidget {
  const _ShopImage({
    this.url,
  });

  final String? url;

  @override
  Widget build(
    BuildContext context,
  ) {
    final valid =
        url != null &&
            url!.trim().isNotEmpty;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        14,
      ),

      child: SizedBox(
        width:
            60,

        height:
            60,

        child: valid
            ? Image.network(
                url!,

                fit:
                    BoxFit.cover,

                errorBuilder:
                    (
                      _,
                      __,
                      ___,
                    ) =>
                        const Icon(
                  Icons
                      .storefront_outlined,
                ),
              )
            : ColoredBox(
                color:
                    Theme.of(context).primaryColor.withOpacity(0.1),

                child:
                    Icon(
                  Icons
                      .storefront_outlined,
                  color: Theme.of(context).primaryColor,
                ),
              ),
      ),
    );
  }
}

class _StatusChip
    extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final String status;

  @override
  Widget build(
    BuildContext context,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    return Chip(
      label:
          Text(
        status.isEmpty
            ? 'unknown'
            : status,
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: primaryColor.withOpacity(0.12),
      side: BorderSide(color: primaryColor.withOpacity(0.3)),

      visualDensity:
          VisualDensity
              .compact,
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;

  final Future<void> Function()
      onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
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
              size:
                  56,
              color: Colors.redAccent,
            ),

            const SizedBox(
              height:
                  12,
            ),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(
              height:
                  16,
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              onPressed: () =>
                  onRetry(),

              child:
                  const Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _serviceNames(
  AppointmentModel appointment,
) {
  final names =
      appointment.services
          .map(
            (
              service,
            ) =>
                service[
                          'service_name'
                      ]
                          ?.toString() ??
                    service[
                          'name'
                      ]
                          ?.toString() ??
                    '',
          )
          .where(
            (
              name,
            ) =>
                name.isNotEmpty,
          )
          .toList();

  if (names.isEmpty) {
    return 'Services unavailable';
  }

  return names.join(
    ', ',
  );
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