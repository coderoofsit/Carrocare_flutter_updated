import 'package:carrocare_flutter/features/bike_wash/domain/entities/bike_wash_service.dart';

abstract class BikeWashRepository {
  Future<BikeWashService> getBikeWashService();
}
