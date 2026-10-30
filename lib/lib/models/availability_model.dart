class AvailabilityModel {
  final String id;
  final String shopId;
  final String? staffId;
  final DateTime? date;
  final int? dayOfWeek;
  final String type;
  final String? startTime;
  final String? endTime;
  final String? reason;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AvailabilityModel({
    required this.id,
    required this.shopId,
    this.staffId,
    this.date,
    this.dayOfWeek,
    required this.type,
    this.startTime,
    this.endTime,
    this.reason,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory AvailabilityModel.fromMap(Map<String, dynamic> map) {
    return AvailabilityModel(
      id: map['id'].toString(),
      shopId: map['shop_id'].toString(),
      staffId: map['staff_id']?.toString(),
      date: map['date'] == null
          ? null
          : DateTime.tryParse(map['date'].toString()),
      dayOfWeek: (map['day_of_week'] as num?)?.toInt(),
      type: map['type']?.toString() ?? 'working',
      startTime: _time(map['start_time']),
      endTime: _time(map['end_time']),
      reason: map['reason']?.toString(),
      status: map['status'] as bool? ?? true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
  }

  static String? _time(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

  bool get isWeekly => date == null && dayOfWeek != null;
  bool get isDateSpecific => date != null;
  bool get isShopLevel => staffId == null;
  bool get isStaffLevel => staffId != null;
  bool get isActive => status;
}
