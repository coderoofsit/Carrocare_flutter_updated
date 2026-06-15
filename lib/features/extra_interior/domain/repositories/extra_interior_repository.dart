import 'package:carrocare_flutter/features/extra_interior/domain/entities/extra_interior_service.dart';

abstract class ExtraInteriorRepository {
  Future<ExtraInteriorService> getExtraInteriorService();
}
