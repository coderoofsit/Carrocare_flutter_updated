class DailyService {
  const DailyService({
    required this.id,
    required this.image,
    required this.type,
    required this.prices,
    required this.description,
    required this.displayPrice,
  });

  final String id;
  final String image;
  final String type;
  final String prices;
  final String description;
  final String displayPrice;
}