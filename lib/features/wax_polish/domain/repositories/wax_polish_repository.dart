import 'package:carrocare_flutter/features/wax_polish/domain/entities/wax_polish_service.dart';

abstract class WaxPolishRepository {
  Future<(String description, List<WaxPolishService> services)>
      getWaxPolishServices();
}
