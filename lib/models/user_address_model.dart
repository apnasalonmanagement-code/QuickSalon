class UserAddressModel {
  final String id;
  final String userId;
  final String label;
  final String fullAddress;
  final String? landmark;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime? createdAt;

  const UserAddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullAddress,
    this.landmark,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    this.createdAt,
  });

  factory UserAddressModel.fromMap(Map<String, dynamic> map) {
    return UserAddressModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      label: (map['label'] ?? 'Other').toString(),
      fullAddress: (map['full_address'] ?? '').toString(),
      landmark: map['landmark']?.toString(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      isDefault: map['is_default'] == true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}
