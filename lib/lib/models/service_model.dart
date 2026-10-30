class ServiceModel {
  final String id;
  final String shopId;
  final String categoryName;
  final String serviceName;
  final int durationMinutes;
  final double price;
  final bool request;
  final bool status;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceModel({
    required this.id,
    required this.shopId,
    required this.categoryName,
    required this.serviceName,
    required this.durationMinutes,
    required this.price,
    required this.request,
    required this.status,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      shopId: map['shop_id'] as String,
      categoryName: (map['category_name'] as String? ?? '').trim(),
      serviceName: (map['service_name'] as String? ?? '').trim(),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0,
      request: map['request'] as bool? ?? false,
      status: map['status'] as bool? ?? true,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }
}
