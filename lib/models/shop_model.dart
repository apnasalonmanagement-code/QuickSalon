class ShopModel {
  final String id;
  final String shopName;
  final String city;
  final String shopType;
  final String? phone;
  final String? locationUrl;
  final String? description;
  final String? imageUrl;
  final double rating;
  final String? openingTime;
  final String? closingTime;
  final bool status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShopModel({
    required this.id,
    required this.shopName,
    required this.city,
    this.shopType = 'salon',
    this.phone,
    this.locationUrl,
    this.description,
    this.imageUrl,
    required this.rating,
    this.openingTime,
    this.closingTime,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    final rawRating = map['rating'];
    return ShopModel(
      id: map['id'].toString(),
      shopName: (map['shop_name'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      shopType: ((map['shop_type'] ?? 'salon').toString().trim().toLowerCase()),
      phone: map['phone'] as String?,
      locationUrl: map['location_url'] as String?,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      rating: rawRating is num
          ? rawRating.toDouble()
          : double.tryParse(rawRating?.toString() ?? '') ?? 0,
      openingTime: map['opening_time']?.toString(),
      closingTime: map['closing_time']?.toString(),
      status: map['status'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }
}
