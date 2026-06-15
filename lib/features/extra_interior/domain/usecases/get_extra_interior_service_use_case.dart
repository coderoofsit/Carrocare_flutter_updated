import 'package:carrocare_flutter/features/extra_interior/domain/entities/extra_interior_service.dart';
import 'package:carrocare_flutter/features/extra_interior/domain/repositories/extra_interior_repository.dart';

class GetExtraInteriorServiceUseCase {
  GetExtraInteriorServiceUseCase(this._repository);

  final ExtraInteriorRepository _repository;

  Future<ExtraInteriorService> call() => _repository.getExtraInteriorService();
}
