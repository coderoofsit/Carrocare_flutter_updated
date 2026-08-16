class CarDetailsArgs {
  const CarDetailsArgs({
    required this.carName,
    required this.carPrice,
    required this.carDesc,
    required this.carImage,
    required this.carId,
    required this.header,
    required this.displayPrice,
  });

  final String carName;
  final String carPrice;
  final String carDesc;
  final String carImage;
  final String carId;
  final String header;
  final String displayPrice;

  /// True catalog price (GST-inclusive) shown to customers and charged at checkout.
  String get catalogPrice => displayPrice.isNotEmpty ? displayPrice : carPrice;
}

