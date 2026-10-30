import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestCard extends StatefulWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onConfirm,
    required this.onReject,
    this.onSaveInstruction,
    this.isProcessing = false,
  });

  final Map<String, dynamic> request;
  final ValueChanged<String> onConfirm;
  final ValueChanged<String> onReject;
  final ValueChanged<String>? onSaveInstruction;
  final bool isProcessing;

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  late final TextEditingController _instructionController;

  @override
  void initState() {
    super.initState();
    _instructionController =
        TextEditingController(
      text:
          widget.request[
                  'shop_instruction']
              ?.toString() ??
              '',
    );
  }

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  String _value(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _customerName() {
    final directName = widget.request['_customer_name'];
    if (directName != null) {
      final name = _value(directName);
      if (name != '-') return name;
    }
    final profile = widget.request['profiles'];
    if (profile is Map) {
      final name = _value(profile['name']);
      if (name != '-') return name;
    }
    return 'Customer';
  }

  String _customerPhone() {
    final directPhone = widget.request['_customer_phone'];
    if (directPhone != null) {
      final phone = _value(directPhone);
      if (phone != '-') return phone;
    }
    final profile = widget.request['profiles'];
    if (profile is Map) {
      return _value(profile['phone']);
    }
    return '-';
  }

  String _staffName() {
    final directName = widget.request['_staff_name'];
    if (directName != null) {
      final name = _value(directName);
      if (name != '-') return name;
    }
    final staff = widget.request['staff'];
    if (staff is Map) {
      final name = _value(staff['name']);
      if (name != '-') return name;
    }
    return _value(widget.request['barber_name_snapshot']);
  }

  String _staffPhone() {
    final directPhone = widget.request['_staff_phone'];
    if (directPhone != null) {
      final phone = _value(directPhone);
      if (phone != '-') return phone;
    }
    final staff = widget.request['staff'];
    if (staff is Map) {
      return _value(staff['phone']);
    }
    return '-';
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString());
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return _value(value);
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.length >= 5) return text.substring(0, 5);
    return text.isEmpty ? '-' : text;
  }

  List<Map<String, dynamic>> _services() {
    final value = widget.request['_services'] ??
        widget.request['services'] ??
        widget.request['appointment_services'];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((service) => Map<String, dynamic>.from(service))
          .toList();
    }
    if (value is Map) {
      return [Map<String, dynamic>.from(value)];
    }
    return [];
  }

  String _number(dynamic value) {
    if (value is num) return value.toStringAsFixed(0);
    return double.tryParse(value?.toString() ?? '')?.toStringAsFixed(0) ?? '0';
  }

  String _servicesText() {
    final services = _services();
    if (services.isEmpty) return 'No service details';

    return services.map((service) {
      final name = _value(service['service_name'] ?? service['service_name_snapshot']);
      final price = service['price'] ?? service['price_snapshot'];
      final duration = service['duration_minutes'] ?? service['duration'];
      final details = <String>[];

      if (duration != null) details.add('$duration min');
      if (price != null) details.add('₹${_number(price)}');

      if (details.isEmpty) return name;
      return '$name (${details.join(' • ')})';
    }).join(', ');
  }

  String _durationText() {
    final duration = widget.request['total_duration_minutes'];
    return duration == null ? '-' : '$duration min';
  }

  String _priceText() {
    final price = widget.request['total_price'];
    return price == null ? '₹0' : '₹${_number(price)}';
  }

  Future<void> _call(BuildContext context, String phone) async {
    if (phone == '-' || phone.trim().isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone.trim());
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Unable to open phone dialer.', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Could not open phone dialer.', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      }
    }
  }

  Widget _infoRow(IconData icon, String title, String value, {bool bold = false, required Color primaryColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 12),
        SizedBox(
          width: 84,
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              fontSize: bold ? 15 : 13.5,
              color: bold ? primaryColor : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final phone = _customerPhone();
    final staffPhone = _staffPhone();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // HEADER
            // ======================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: primaryColor.withOpacity(0.15),
                  child: Text(
                    _customerName().isNotEmpty ? _customerName()[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _customerName(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.orange.withOpacity(0.12),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              ],
            ),

            // ======================================================
            // CALL CUSTOMER
            // ======================================================
            if (phone != '-') ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _call(context, phone),
                  icon: Icon(Icons.call, size: 16, color: primaryColor),
                  label: Text('Call Customer', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ======================================================
            // APPOINTMENT DETAILS
            // ======================================================
            _infoRow(Icons.calendar_today_outlined, 'Date', _formatDate(widget.request['booking_date']), primaryColor: primaryColor),
            const SizedBox(height: 10),
            _infoRow(Icons.access_time, 'Time', '${_formatTime(widget.request['start_time'])} - ${_formatTime(widget.request['end_time'])}', primaryColor: primaryColor),
            const SizedBox(height: 10),
            _infoRow(Icons.person_outline, 'Staff', _staffName(), primaryColor: primaryColor),

            if (staffPhone != '-') ...[
              const SizedBox(height: 10),
              _infoRow(Icons.phone_outlined, 'Staff Phone', staffPhone, primaryColor: primaryColor),
            ],

            const SizedBox(height: 10),
            _infoRow(Icons.content_cut_outlined, 'Services', _servicesText(), primaryColor: primaryColor),
            const SizedBox(height: 10),
            _infoRow(Icons.timer_outlined, 'Duration', _durationText(), primaryColor: primaryColor),
            const SizedBox(height: 10),
            _infoRow(Icons.currency_rupee, 'Total', _priceText(), bold: true, primaryColor: primaryColor),

            const SizedBox(height: 18),

            // ======================================================
            // SHOP INSTRUCTION
            // ======================================================
            TextField(
              controller: _instructionController,
              maxLines: 3,
              maxLength: 250,
              enabled: !widget.isProcessing,
              decoration: InputDecoration(
                labelText: 'Shop instruction',
                hintText: 'Message for confirm/reject or general instruction',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
              ),
            ),

            // ======================================================
            // SAVE INSTRUCTION
            // ======================================================
            if (widget.onSaveInstruction != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: widget.isProcessing
                      ? null
                      : () {
                          widget.onSaveInstruction!(
                            _instructionController.text.trim(),
                          );
                        },
                  icon: Icon(Icons.save_outlined, size: 16, color: primaryColor),
                  label: Text('Send Message', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // ======================================================
            // ACTIONS
            // ======================================================
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isProcessing
                        ? null
                        : () {
                            widget.onReject(
                              _instructionController.text.trim(),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.isProcessing
                        ? null
                        : () {
                            widget.onConfirm(
                              _instructionController.text.trim(),
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: widget.isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
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
