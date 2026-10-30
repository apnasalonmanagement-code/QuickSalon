class ProfileModel {
  final String id;
  final String name;
  final String? phone;
  final String? city;
  final DateTime? dob;
  final String role;
  final String? shopId;
  final String? profileImageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProfileModel({
    required this.id,
    required this.name,
    this.phone,
    this.city,
    this.dob,
    required this.role,
    this.shopId,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      city: map['city'] as String?,
      dob: map['dob'] != null
          ? DateTime.tryParse(map['dob'].toString())
          : null,
      role: map['role'] as String? ?? 'customer',
      shopId: map['shop_id'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  bool get isManagementUser {
    return role == 'manager' || role == 'owner';
  }

  bool get hasShop {
    return shopId != null && shopId!.isNotEmpty;
  }
}