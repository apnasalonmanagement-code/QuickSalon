import 'dart:convert';

import 'package:flutter/material.dart';

class AppointmentCard
    extends StatefulWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onConfirm,
    this.onReject,
    this.onCancel,
    this.onComplete,
    this.onSaveInstruction,
    this.isProcessing = false,
  });

  final Map<String, dynamic> appointment;

  final ValueChanged<String>? onConfirm;

  final ValueChanged<String>? onReject;

  final ValueChanged<String>? onCancel;

  final ValueChanged<String>? onComplete;

  final ValueChanged<String>? onSaveInstruction;

  final bool isProcessing;

  @override
  State<AppointmentCard> createState() =>
      _AppointmentCardState();
}

class _AppointmentCardState
    extends State<AppointmentCard> {

  late final TextEditingController
      _instructionController;

  @override
  void initState() {
    super.initState();

    _instructionController =
        TextEditingController(
      text: widget.appointment[
              'shop_instruction']
          ?.toString() ??
          '',
    );
  }

  @override
  void didUpdateWidget(
    covariant AppointmentCard oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.appointment[
              'shop_instruction']
            ?.toString() !=
        widget.appointment[
              'shop_instruction']
            ?.toString()) {
      final value =
          widget.appointment[
                  'shop_instruction']
              ?.toString() ??
              '';

      if (value !=
          _instructionController.text) {
        _instructionController.text =
            value;
      }
    }
  }

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  // ============================================================
  // GENERIC VALUE
  // ============================================================

  String _value(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    final text =
        value.toString().trim();

    return text.isEmpty
        ? '-'
        : text;
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    dynamic value,
  ) {
    if (value == null) {
      return '-';
    }

    try {
      final date =
          DateTime.parse(
        value.toString(),
      );

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
    dynamic value,
  ) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.isEmpty) return '-';
    final parts = text.split(':');
    if (parts.length < 2) return text;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return text;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _status() {
    final status =
        widget.appointment['status'];

    if (status == null) {
      return 'UNKNOWN';
    }

    final text =
        status.toString().trim();

    if (text.isEmpty) {
      return 'UNKNOWN';
    }

    return text
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
    BuildContext context,
  ) {
    final status =
        widget.appointment['status']
            ?.toString()
            .toLowerCase();

    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'held':
        return Colors.orange;

      case 'confirmed':
        return Colors.green;

      case 'completed':
        return Colors.blue;

      case 'rejected':
        return Colors.red;

      case 'cancelled':
        return Colors.red;

      case 'expired':
        return Colors.grey;

      default:
        return Theme.of(
          context,
        ).colorScheme.primary;
    }
  }

  // ============================================================
  // CUSTOMER NAME
  // ============================================================

  String _customerName() {
    // ----------------------------------------------------------
    // Controller convenience field
    // ----------------------------------------------------------

    final convenienceName =
        widget.appointment[
            '_customer_name'];

    if (convenienceName != null) {
      final name =
          convenienceName
              .toString()
              .trim();

      if (name.isNotEmpty &&
          name != 'Customer') {
        return name;
      }
    }

    // ----------------------------------------------------------
    // Nested profile fallback
    // ----------------------------------------------------------

    final profile =
        widget.appointment['profiles'];

    if (profile is Map) {
      final name =
          profile['name']
              ?.toString()
              .trim();

      if (name != null &&
          name.isNotEmpty) {
        return name;
      }
    }

    // ----------------------------------------------------------
    // Nested customer fallback
    // ----------------------------------------------------------

    final customer =
        widget.appointment['customer'];

    if (customer is Map) {
      final name =
          customer['name']
              ?.toString()
              .trim();

      if (name != null &&
          name.isNotEmpty) {
        return name;
      }
    }

    // ----------------------------------------------------------
    // Additional possible field
    // ----------------------------------------------------------

    final snapshot =
        widget.appointment[
            'customer_name_snapshot'];

    if (snapshot != null) {
      final name =
          snapshot
              .toString()
              .trim();

      if (name.isNotEmpty) {
        return name;
      }
    }

    return 'Customer';
  }

  // ============================================================
  // CUSTOMER IMAGE
  // ============================================================

  String _customerImage() {
    final image =
        widget.appointment[
            '_customer_image'];

    if (image != null) {
      final value =
          image.toString().trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    final profile =
        widget.appointment['profiles'];

    if (profile is Map) {
      final image =
          profile[
                  'profile_image_url']
              ?.toString()
              .trim();

      if (image != null &&
          image.isNotEmpty) {
        return image;
      }
    }

    return '';
  }

  // ============================================================
  // STAFF NAME
  // ============================================================

  String _staffName() {
    // ----------------------------------------------------------
    // Controller convenience field
    // ----------------------------------------------------------

    final convenienceName =
        widget.appointment[
            '_staff_name'];

    if (convenienceName != null) {
      final name =
          convenienceName
              .toString()
              .trim();

      if (name.isNotEmpty &&
          name != 'Staff') {
        return name;
      }
    }

    // ----------------------------------------------------------
    // Nested staff object
    // ----------------------------------------------------------

    final staff =
        widget.appointment['staff'];

    if (staff is Map) {
      final name =
          staff['name']
              ?.toString()
              .trim();

      if (name != null &&
          name.isNotEmpty) {
        return name;
      }
    }

    // ----------------------------------------------------------
    // Old snapshot fallback
    // ----------------------------------------------------------

    final snapshot =
        widget.appointment[
            'barber_name_snapshot'];

    if (snapshot != null) {
      final name =
          snapshot
              .toString()
              .trim();

      if (name.isNotEmpty) {
        return name;
      }
    }

    return 'Staff';
  }

  // ============================================================
  // STAFF PHONE
  // ============================================================

  String _staffPhone() {
    final conveniencePhone =
        widget.appointment[
            '_staff_phone'];

    if (conveniencePhone != null) {
      final phone =
          conveniencePhone
              .toString()
              .trim();

      if (phone.isNotEmpty &&
          phone != '-') {
        return phone;
      }
    }

    final staff =
        widget.appointment['staff'];

    if (staff is Map) {
      final phone =
          staff['phone']
              ?.toString()
              .trim();

      if (phone != null &&
          phone.isNotEmpty) {
        return phone;
      }
    }

    return '-';
  }

  // ============================================================
  // STAFF IMAGE
  // ============================================================

  String _staffImage() {
    final image =
        widget.appointment[
            '_staff_image'];

    if (image != null) {
      final value =
          image.toString().trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    final staff =
        widget.appointment['staff'];

    if (staff is Map) {
      final image =
          staff['image_url']
              ?.toString()
              .trim();

      if (image != null &&
          image.isNotEmpty) {
        return image;
      }
    }

    return '';
  }

  // ============================================================
  // STAFF ROLE
  // ============================================================

  String _staffRole() {
    final role =
        widget.appointment[
            '_staff_role'];

    if (role != null) {
      final value =
          role.toString().trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    final staff =
        widget.appointment['staff'];

    if (staff is Map) {
      final role =
          staff['role']
              ?.toString()
              .trim();

      if (role != null &&
          role.isNotEmpty) {
        return role;
      }
    }

    return '';
  }

  // ============================================================
  // SERVICES
  // ============================================================

  List<Map<String, dynamic>>
      _services() {
    // ----------------------------------------------------------
    // Controller normalized services
    // ----------------------------------------------------------

    final normalized =
        widget.appointment[
            '_services'];

    if (normalized is List) {
      final result =
          <Map<String, dynamic>>[];

      for (final service
          in normalized) {
        if (service is Map) {
          result.add(
            Map<String, dynamic>.from(
              service,
            ),
          );
        }
      }

      if (result.isNotEmpty) {
        return result;
      }
    }

    // ----------------------------------------------------------
    // Actual database field
    //
    // appointments.services
    // ----------------------------------------------------------

    final databaseServices =
        widget.appointment[
            'services'];

    if (databaseServices is List) {
      final result =
          <Map<String, dynamic>>[];

      for (final service
          in databaseServices) {
        if (service is Map) {
          result.add(
            Map<String, dynamic>.from(
              service,
            ),
          );
        }
      }

      return result;
    }

    // ----------------------------------------------------------
    // JSONB may arrive as String
    // ----------------------------------------------------------

    if (databaseServices is String) {
      try {
        final decoded =
            jsonDecode(
          databaseServices,
        );

        if (decoded is List) {
          final result =
              <Map<String, dynamic>>[];

          for (final service
              in decoded) {
            if (service is Map) {
              result.add(
                Map<String, dynamic>.from(
                  service,
                ),
              );
            }
          }

          return result;
        }

        if (decoded is Map) {
          return [
            Map<String, dynamic>.from(
              decoded,
            ),
          ];
        }
      } catch (_) {
        return [];
      }
    }

    // ----------------------------------------------------------
    // Old field fallback
    // ----------------------------------------------------------

    final oldServices =
        widget.appointment[
            'appointment_services'];

    if (oldServices is List) {
      final result =
          <Map<String, dynamic>>[];

      for (final service
          in oldServices) {
        if (service is Map) {
          result.add(
            Map<String, dynamic>.from(
              service,
            ),
          );
        }
      }

      return result;
    }

    return [];
  }

  // ============================================================
  // SERVICE NAME
  // ============================================================

  String _serviceName(
    Map<String, dynamic> service,
  ) {
    // ----------------------------------------------------------
    // Current database field
    // ----------------------------------------------------------

    final name =
        service['service_name'];

    if (name != null) {
      final text =
          name.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    // ----------------------------------------------------------
    // Generic name fallback
    // ----------------------------------------------------------

    final serviceName =
        service['name'];

    if (serviceName != null) {
      final text =
          serviceName.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    // ----------------------------------------------------------
    // Snapshot fallback
    // ----------------------------------------------------------

    final snapshot =
        service[
            'service_name_snapshot'];

    if (snapshot != null) {
      final text =
          snapshot.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Service';
  }

  // ============================================================
  // SERVICE PRICE
  // ============================================================

  dynamic _servicePrice(
    Map<String, dynamic> service,
  ) {
    final price =
        service['price'];

    if (price != null) {
      return price;
    }

    final snapshot =
        service['price_snapshot'];

    if (snapshot != null) {
      return snapshot;
    }

    return null;
  }

  // ============================================================
  // SERVICES TEXT
  // ============================================================

  String _servicesText() {
    final services =
        _services();

    if (services.isEmpty) {
      return 'No service details';
    }

    final List<String>
        serviceTexts = [];

    for (final service
        in services) {
      final name =
          _serviceName(
        service,
      );

      final price =
          _servicePrice(
        service,
      );

      if (price == null) {
        serviceTexts.add(
          name,
        );
      } else {
        serviceTexts.add(
          '$name (₹$price)',
        );
      }
    }

    if (serviceTexts.isEmpty) {
      return 'No service details';
    }

    return serviceTexts.join(
      ', ',
    );
  }

  // ============================================================
  // SERVICE COUNT
  // ============================================================

  String _serviceCountText() {
    final services =
        _services();

    if (services.isEmpty) {
      return '';
    }

    if (services.length == 1) {
      return '1 service';
    }

    return '${services.length} services';
  }

  // ============================================================
  // DURATION
  // ============================================================

  String _durationText() {
    final duration =
        widget.appointment[
            'total_duration_minutes'];

    if (duration == null) {
      return '-';
    }

    final value =
        duration.toString().trim();

    if (value.isEmpty) {
      return '-';
    }

    return '$value min';
  }

  // ============================================================
  // TOTAL PRICE
  // ============================================================

  String _priceText() {
    final price =
        widget.appointment[
            'total_price'];

    if (price == null) {
      return '₹0';
    }

    final value =
        price.toString().trim();

    if (value.isEmpty) {
      return '₹0';
    }

    return '₹$value';
  }

  // ============================================================
  // BOOKING TYPE
  // ============================================================

  String _bookingType() {
    final type =
        widget.appointment[
            'booking_type'];

    if (type == null) {
      return '';
    }

    final value =
        type.toString().trim();

    if (value.isEmpty) {
      return '';
    }

    return value
        .replaceAll('_', ' ')
        .toUpperCase();
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _customerAvatar(
    BuildContext context,
    String customerName,
  ) {
    final image =
        _customerImage();

    if (image.isNotEmpty) {
      return CircleAvatar(
        radius: 25,
        backgroundImage:
            NetworkImage(
          image,
        ),
        onBackgroundImageError:
            (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 25,
      child: Text(
        customerName.isNotEmpty
            ? customerName[0]
                .toUpperCase()
            : '?',
        style: const TextStyle(
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // STAFF AVATAR
  // ============================================================

  Widget _staffAvatar(
    BuildContext context,
    String staffName,
  ) {
    final image =
        _staffImage();

    if (image.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage:
            NetworkImage(
          image,
        ),
        onBackgroundImageError:
            (_, __) {},
      );
    }

    return CircleAvatar(
      radius: 18,
      child: Text(
        staffName.isNotEmpty
            ? staffName[0]
                .toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 13,
          fontWeight:
              FontWeight.bold,
        ),
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
    final theme =
        Theme.of(context);

    final customerName =
        _customerName();

    final staffName =
        _staffName();

    final staffPhone =
        _staffPhone();

    final staffRole =
        _staffRole();

    final status =
        _status();

    final statusColor =
        _statusColor(
      context,
    );

    final bookingType =
        _bookingType();

    final serviceCount =
        _serviceCountText();

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 2,
      clipBehavior:
          Clip.antiAlias,
      child: Padding(
        padding:
            const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _customerAvatar(
                  context,
                  customerName,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                    color: statusColor
                        .withValues(
                      alpha: 0.12,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DATE / TIME
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons
                      .calendar_today_outlined,
                  size: 18,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    _formatDate(
                      widget.appointment[
                          'booking_date'],
                    ),
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                const Icon(
                  Icons.access_time,
                  size: 18,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    '${_formatTime(widget.appointment['start_time'])}'
                    ' - '
                    '${_formatTime(widget.appointment['end_time'])}',
                    textAlign:
                        TextAlign.end,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // BOOKING TYPE
            // ==================================================

            if (bookingType.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  bottom: 10,
                ),
                child: _InfoRow(
                  icon:
                      Icons.bookmark_outline,
                  title:
                      'Booking',
                  value:
                      bookingType,
                ),
              ),

            // ==================================================
            // SERVICES
            // ==================================================

            _InfoRow(
              icon:
                  Icons.content_cut_outlined,
              title:
                  'Services',
              value:
                  _servicesText(),
            ),

            if (serviceCount.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  left: 29,
                  top: 4,
                ),
                child: Text(
                  serviceCount,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: theme
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(
                      alpha: 0.65,
                    ),
                  ),
                ),
              ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // STAFF
            // ==================================================

            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 19,
                ),

                const SizedBox(
                  width: 10,
                ),

                const SizedBox(
                  width: 80,
                  child: Text(
                    'Staff',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                _staffAvatar(
                  context,
                  staffName,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                      if (staffRole.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            top: 2,
                          ),
                          child:
                              Text(
                            staffRole
                                .replaceAll(
                              '_',
                              ' ',
                            ),
                            style:
                                theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // ==================================================
            // STAFF PHONE
            // ==================================================

            if (staffPhone != '-')
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 10,
                ),
                child: _InfoRow(
                  icon:
                      Icons.phone_outlined,
                  title:
                      'Phone',
                  value:
                      staffPhone,
                ),
              ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // TOTAL DURATION
            // ==================================================

            _InfoRow(
              icon:
                  Icons.timer_outlined,
              title:
                  'Duration',
              value:
                  _durationText(),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // TOTAL PRICE
            // ==================================================

            _InfoRow(
              icon:
                  Icons.currency_rupee,
              title:
                  'Total',
              value:
                  _priceText(),
              valueBold:
                  true,
            ),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // SHOP INSTRUCTION
            // ==================================================

            TextField(
              controller:
                  _instructionController,
              maxLines: 2,
              maxLength: 250,
              decoration:
                  const InputDecoration(
                labelText:
                    'Shop instruction',
                hintText:
                    'Optional message / cancellation instruction',
                border:
                    OutlineInputBorder(),
              ),
            ),

            if (widget.onSaveInstruction !=
                null)
              Align(
                alignment:
                    Alignment.centerRight,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      widget.isProcessing
                          ? null
                          : () =>
                              widget
                                  .onSaveInstruction!(
                                _instructionController
                                    .text
                                    .trim(),
                              ),
                  icon:
                      const Icon(
                    Icons.save_outlined,
                    size: 18,
                  ),
                  label:
                      const Text(
                    'Send Message',
                  ),
                ),
              ),

            const Divider(),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            _buildActions(
              context,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(
    BuildContext context,
  ) {
    final hasActions =
        widget.onConfirm != null ||
        widget.onReject != null ||
        widget.onCancel != null ||
        widget.onComplete != null;

    if (!hasActions) {
      return _buildNoActionsMessage(
        context,
      );
    }

    final buttons =
        <Widget>[];

    // ----------------------------------------------------------
    // REJECT
    // ----------------------------------------------------------

    if (widget.onReject != null) {
      buttons.add(
        Expanded(
          child:
              OutlinedButton(
            onPressed:
                widget.isProcessing
                    ? null
                    : () =>
                        widget.onReject!(
                      _instructionController
                          .text
                          .trim(),
                    ),
            style:
                OutlinedButton
                    .styleFrom(
              minimumSize:
                  const Size(
                0,
                46,
              ),
            ),
            child:
                const Text(
              'Reject',
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // CANCEL
    // ----------------------------------------------------------

    if (widget.onCancel != null) {
      if (buttons.isNotEmpty) {
        buttons.add(
          const SizedBox(
            width: 10,
          ),
        );
      }

      buttons.add(
        Expanded(
          child:
              OutlinedButton(
            onPressed:
                widget.isProcessing
                    ? null
                    : () =>
                        widget.onCancel!(
                      _instructionController
                          .text
                          .trim(),
                    ),
            style:
                OutlinedButton
                    .styleFrom(
              minimumSize:
                  const Size(
                0,
                46,
              ),
            ),
            child:
                const Text(
              'Cancel',
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // CONFIRM
    // ----------------------------------------------------------

    if (widget.onConfirm != null) {
      if (buttons.isNotEmpty) {
        buttons.add(
          const SizedBox(
            width: 10,
          ),
        );
      }

      buttons.add(
        Expanded(
          child:
              FilledButton(
            onPressed:
                widget.isProcessing
                    ? null
                    : () =>
                        widget.onConfirm!(
                      _instructionController
                          .text
                          .trim(),
                    ),
            style:
                FilledButton
                    .styleFrom(
              minimumSize:
                  const Size(
                0,
                46,
              ),
            ),
            child:
                widget.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Text(
                        'Confirm',
                      ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // COMPLETE
    // ----------------------------------------------------------

    if (widget.onComplete != null) {
      if (buttons.isNotEmpty) {
        buttons.add(
          const SizedBox(
            width: 10,
          ),
        );
      }

      buttons.add(
        Expanded(
          child:
              FilledButton(
            onPressed:
                widget.isProcessing
                    ? null
                    : () =>
                        widget.onComplete!(
                      _instructionController
                          .text
                          .trim(),
                    ),
            style:
                FilledButton
                    .styleFrom(
              minimumSize:
                  const Size(
                0,
                46,
              ),
            ),
            child:
                widget.isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      )
                    : const Text(
                        'Complete',
                      ),
          ),
        ),
      );
    }

    return Row(
      children: buttons,
    );
  }

  // ============================================================
  // NO ACTIONS
  // ============================================================

  Widget _buildNoActionsMessage(
    BuildContext context,
  ) {
    final status =
        widget.appointment['status']
            ?.toString()
            .toLowerCase();

    String message =
        'No actions available';

    if (status == 'completed') {
      message =
          'Appointment completed';
    } else if (status == 'rejected') {
      message =
          'Appointment rejected';
    } else if (status == 'cancelled') {
      message =
          'Appointment cancelled';
    } else if (status == 'expired') {
      message =
          'Appointment expired';
    }

    return SizedBox(
      width: double.infinity,
      child: Text(
        message,
        textAlign:
            TextAlign.center,
        style: Theme.of(
          context,
        )
            .textTheme
            .bodyMedium
            ?.copyWith(
              fontWeight:
                  FontWeight.w600,
            ),
      ),
    );
  }
}

// ==================================================================
// INFO ROW
// ==================================================================

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueBold = false,
  });

  final IconData icon;

  final String title;

  final String value;

  final bool valueBold;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
        ),

        const SizedBox(
          width: 10,
        ),

        SizedBox(
          width: 80,
          child: Text(
            title,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight:
                  valueBold
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}