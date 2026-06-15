import 'package:carrocare_flutter/features/wax_polish/domain/entities/wax_polish_service.dart';
import 'package:carrocare_flutter/features/wax_polish/domain/repositories/wax_polish_repository.dart';

class GetWaxPolishServicesUseCase {
  GetWaxPolishServicesUseCase(this._repository);

  final WaxPolishRepository _repository;

  Future<(String description, List<WaxPolishService> services)> call() =>
      _repository.getWaxPolishServices();
}
