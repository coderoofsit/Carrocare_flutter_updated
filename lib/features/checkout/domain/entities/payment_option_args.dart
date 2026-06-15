import 'package:carrocare_flutter/features/car_details/domain/entities/car_details_args.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';

class PaymentOptionArgs {
  const PaymentOptionArgs({
    required this.booking,
    required this.vehicle,
  });

  final CarDetailsArgs booking;
  final VehicleItem vehicle;

  String get serviceType => booking.header;
  String get carPrice => booking.carPrice;
  String get carName => booking.carName;
}
