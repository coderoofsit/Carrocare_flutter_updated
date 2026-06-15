import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';
import 'package:carrocare_flutter/features/disinfection/domain/repositories/disinfection_repository.dart';

class GetDisinfectionServicesUseCase {
  GetDisinfectionServicesUseCase(this._repository);

  final DisinfectionRepository _repository;

  Future<(String description, List<DailyService> services)> call() {
    return _repository.getDisinfectionServices();
  }
}
