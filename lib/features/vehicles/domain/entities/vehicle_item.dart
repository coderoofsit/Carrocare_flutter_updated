class VehicleItem {
  const VehicleItem({
    required this.id,
    required this.make,
    required this.model,
    required this.vehicleNo,
    required this.color,
    required this.apartmentName,
    required this.parkingLotNo,
    required this.parkingArea,
    required this.preferredSchedule,
    required this.preferredTime,
    required this.image,
    required this.category,
    required this.vehicleType,
  });

  final String id;
  final String make;
  final String model;
  final String vehicleNo;
  final String color;
  final String apartmentName;
  final String parkingLotNo;
  final String parkingArea;
  final String preferredSchedule;
  final String preferredTime;
  final String image;
  final String category;
  final String vehicleType;

  String get makeModel => '$make-$model';
}