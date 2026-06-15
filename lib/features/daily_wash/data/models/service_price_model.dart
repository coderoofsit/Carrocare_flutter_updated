class ServicePriceModel {
  ServicePriceModel({
    required this.status,
    required this.code,
    required this.description,
    required this.services,
  });

  final String status;
  final String code;
  final String description;
  final List<DailyServiceModel> services;

  factory ServicePriceModel.fromJson(Map<String, dynamic> json) {
    final rawServices = json['services'];
    final list = rawServices is List
        ? rawServices
              .whereType<Map>()
              .map(
                (item) => DailyServiceModel.fromJson(
                  item.map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                ),
              )
              .toList()
        : <DailyServiceModel>[];

    return ServicePriceModel(
      status: (json['status'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      services: list,
    );
  }
}

class DailyServiceModel {
  DailyServiceModel({
    required this.id,
    required this.image,
    required this.type,
    required this.prices,
    required this.description,
    required this.serviceGstPercentage,
  });

  final String id;
  final String image;
  final String type;
  final String prices;
  final String description;
  final String serviceGstPercentage;

  factory DailyServiceModel.fromJson(Map<String, dynamic> json) {
    return DailyServiceModel(
      id: (json['id'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      prices: (json['prices'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      serviceGstPercentage: (json['service_gst_percentage'] ?? '').toString(),
    );
  }
}
