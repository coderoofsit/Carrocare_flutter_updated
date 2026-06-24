import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
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
    final gstFromApi = model.services
        .map((service) => int.tryParse(service.serviceGstPercentage) ?? 0)
        .firstWhere((value) => value > 0, orElse: () => 0);
    final gstPercent = gstFromApi > 0
        ? gstFromApi
        : CheckoutGstConfig.resolvePercent(prefs);
    await CheckoutGstConfig.persistPercent(prefs, gstPercent);

    final services = model.services.map((service) {
      final inclusivePrice = int.tryParse(service.prices) ?? 0;
      final exclusivePrice =
          CheckoutPricing.exclusiveAmount(inclusivePrice, gstPercent);
      return DailyService(
        id: service.id,
        image: service.image,
        type: service.type,
        prices: exclusivePrice.toString(),
        description: service.description,
        displayPrice: inclusivePrice.toString(),
      );
    }).toList();
    return (model.description, services);
  }
}
