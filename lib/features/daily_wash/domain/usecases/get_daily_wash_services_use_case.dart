import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/repositories/daily_wash_repository.dart';

class GetDailyWashServicesUseCase {
  GetDailyWashServicesUseCase(this._repository);

  final DailyWashRepository _repository;

  Future<(String description, List<DailyService> services)> call() {
    return _repository.getDailyCarWashServices();
  }
}
