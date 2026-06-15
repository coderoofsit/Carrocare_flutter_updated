import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';
import 'package:carrocare_flutter/features/disinfection/data/datasources/disinfection_remote_data_source.dart';
import 'package:carrocare_flutter/features/disinfection/domain/repositories/disinfection_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisinfectionRepositoryImpl implements DisinfectionRepository {
  DisinfectionRepositoryImpl(this._remoteDataSource);

  final DisinfectionRemoteDataSource _remoteDataSource;

  @override
  Future<(String description, List<DailyService> services)>
      getDisinfectionServices() async {
    final model = await _remoteDataSource.getDisinfectionServices();
    if (model.code != '200') {
      throw Exception(model.description.isEmpty ? 'Failed to load' : model.description);
    }
    final prefs = await SharedPreferences.getInstance();
    final gstPercent =
        int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;

    final services = model.services.map((service) {
      final parsedPrice = int.tryParse(service.prices) ?? 0;
      final taxAmt = (gstPercent * parsedPrice) ~/ 100;
      return DailyService(
        id: service.id,
        image: service.image,
        type: service.type,
        prices: service.prices,
        description: service.description,
        displayPrice: (taxAmt + parsedPrice).toString(),
      );
    }).toList();
    return (model.description, services);
  }
}
