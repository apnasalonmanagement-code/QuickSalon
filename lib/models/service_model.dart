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
    final rawPrice = map['price'];
    final rawDuration = map['duration_minutes'];

    return ServiceModel(
      id: map['id'].toString(),
      shopId: map['shop_id'].toString(),
      categoryName: (map['category_name'] ?? '').toString(),
      serviceName: (map['service_name'] ?? '').toString(),
      durationMinutes: rawDuration is num
          ? rawDuration.toInt()
          : int.tryParse(rawDuration?.toString() ?? '') ?? 0,
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '') ?? 0,
      request: map['request'] == true,
      status: map['status'] == true,
      imageUrl: map['image_url']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }
}
