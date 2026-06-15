import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/wax_polish/data/datasources/wax_polish_remote_data_source.dart';
import 'package:carrocare_flutter/features/wax_polish/domain/entities/wax_polish_service.dart';
import 'package:carrocare_flutter/features/wax_polish/domain/repositories/wax_polish_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaxPolishRepositoryImpl implements WaxPolishRepository {
  WaxPolishRepositoryImpl(this._remoteDataSource);

  final WaxPolishRemoteDataSource _remoteDataSource;

  @override
  Future<(String description, List<WaxPolishService> services)>
      getWaxPolishServices() async {
    final model = await _remoteDataSource.getWaxPolishServices();
    if (model.code != '200') {
      throw Exception('Invalid response code');
    }

    final prefs = await SharedPreferences.getInstance();
    final gstPercent =
        int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;

    final services = model.services
        .where((service) => service.id != '4')
        .map((service) {
          final inclusivePrice = int.tryParse(service.prices) ?? 0;
          final exclusivePrice =
              CheckoutPricing.exclusiveAmount(inclusivePrice, gstPercent);
          return WaxPolishService(
            id: service.id,
            image: service.image,
            type: service.type,
            price: exclusivePrice.toString(),
            description: service.description,
            displayPrice: inclusivePrice.toString(),
          );
        })
        .toList();

    return (model.description, services);
  }
}
