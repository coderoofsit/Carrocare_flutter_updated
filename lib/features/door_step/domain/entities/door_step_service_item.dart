class DoorStepServiceItem {
  const DoorStepServiceItem({
    required this.service,
    required this.image,
    required this.type,
    required this.prices,
    required this.description,
    required this.status,
  });

  final String service;
  final String image;
  final String type;
  final String prices;
  final String description;
  final String status;

  factory DoorStepServiceItem.fromJson(Map<String, dynamic> json) {
    return DoorStepServiceItem(
      service: (json['service'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      prices: (json['prices'] ?? '0').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}
