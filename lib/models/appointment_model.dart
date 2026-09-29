class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.shopId,
    required this.customerId,
    this.staffId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.services,
    required this.totalDurationMinutes,
    required this.totalPrice,
    required this.bookingType,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.expiresAt,
    this.shopName,
    this.shopImageUrl,
    this.staffName,
    this.staffImageUrl,
  });

  final String id;
  final String shopId;
  final String customerId;
  final String? staffId;

  final DateTime bookingDate;
  final String startTime;
  final String endTime;

  final List<Map<String, dynamic>> services;

  final int totalDurationMinutes;
  final double totalPrice;

  final String bookingType;
  final String status;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;

  // Display-only data loaded from existing shops/staff tables.
  final String? shopName;
  final String? shopImageUrl;
  final String? staffName;
  final String? staffImageUrl;

  factory AppointmentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AppointmentModel(
      id: map['id']?.toString() ?? '',
      shopId: map['shop_id']?.toString() ?? '',
      customerId: map['customer_id']?.toString() ?? '',
      staffId: _nullableString(
        map['staff_id'],
      ),
      bookingDate: _parseDate(
        map['booking_date'],
      ),
      startTime: map['start_time']?.toString() ?? '',
      endTime: map['end_time']?.toString() ?? '',
      services: _normalizeServices(
        map['services'],
      ),
      totalDurationMinutes: _parseInt(
        map['total_duration_minutes'],
      ),
      totalPrice: _parseDouble(
        map['total_price'],
      ),
      bookingType: map['booking_type']?.toString() ?? '',
      status: map['status']
              ?.toString()
              .toLowerCase() ??
          '',
      createdAt: _parseDateTime(
        map['created_at'],
      ),
      updatedAt: _parseDateTime(
        map['updated_at'],
      ),
      expiresAt: _parseDateTime(
        map['expires_at'],
      ),
      shopName: _nullableString(
        map['_shop_name'],
      ),
      shopImageUrl: _nullableString(
        map['_shop_image'],
      ),
      staffName: _nullableString(
        map['_staff_name'],
      ),
      staffImageUrl: _nullableString(
        map['_staff_image'],
      ),
    );
  }

  DateTime get scheduledAt {
    final parts = startTime.split(':');

    final hour =
        parts.isNotEmpty
            ? int.tryParse(parts[0]) ?? 0
            : 0;

    final minute =
        parts.length > 1
            ? int.tryParse(parts[1]) ?? 0
            : 0;

    return DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      hour,
      minute,
    );
  }

  static DateTime _parseDate(
    dynamic value,
  ) {
    final text =
        value?.toString() ?? '';

    final parsed =
        DateTime.tryParse(text);

    if (parsed == null) {
      return DateTime.fromMillisecondsSinceEpoch(
        0,
      );
    }

    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
    );
  }

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static int _parseInt(
    dynamic value,
  ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _parseDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static String? _nullableString(
    dynamic value,
  ) {
    final text =
        value?.toString().trim();

    if (text == null ||
        text.isEmpty) {
      return null;
    }

    return text;
  }

  static List<Map<String, dynamic>>
      _normalizeServices(
    dynamic value,
  ) {
    if (value is List) {
      final result =
          <Map<String, dynamic>>[];

      for (final item in value) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }

      return result;
    }

    if (value is Map) {
      return [
        Map<String, dynamic>.from(
          value,
        ),
      ];
    }

    return const [];
  }
}