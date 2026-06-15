import 'package:carrocare_flutter/features/bike_wash/domain/entities/bike_wash_service.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/repositories/bike_wash_repository.dart';

class GetBikeWashServiceUseCase {
  GetBikeWashServiceUseCase(this._repository);

  final BikeWashRepository _repository;

  Future<BikeWashService> call() => _repository.getBikeWashService();
}
