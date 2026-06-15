import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';

abstract class DailyWashRepository {
  Future<(String description, List<DailyService> services)>
  getDailyCarWashServices();
}
