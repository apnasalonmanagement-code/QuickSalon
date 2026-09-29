class StaffModel {
  const StaffModel({
    required this.id,
    required this.shopId,
    required this.name,
    this.phone,
    this.role,
    this.imageUrl,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String shopId;
  final String name;
  final String? phone;
  final String? role;
  final String? imageUrl;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    return StaffModel(
      id: map['id']?.toString() ?? '',
      shopId: map['shop_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString(),
      role: map['role']?.toString(),
      imageUrl: map['image_url']?.toString(),
      status: map['status'] == true,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
    );
  }
}
