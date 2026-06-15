import 'package:carrocare_flutter/features/bike_wash/data/datasources/bike_wash_remote_data_source.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/entities/bike_wash_service.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/repositories/bike_wash_repository.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BikeWashRepositoryImpl implements BikeWashRepository {
  BikeWashRepositoryImpl(this._remoteDataSource);

  final BikeWashRemoteDataSource _remoteDataSource;

  @override
  Future<BikeWashService> getBikeWashService() async {
    final data = await _remoteDataSource.getBikeWashRawResponse();
    final code = (data['code'] ?? '').toString();
    if (code != '200') {
      throw Exception('Invalid response code');
    }

    final rawServices = data['services'];
    if (rawServices is! List) {
      throw Exception('Invalid services payload');
    }

    Map<String, dynamic>? bikeItem;
    for (final item in rawServices) {
      if (item is! Map) continue;
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final type = (map['type'] ?? '').toString();
      if (type.toLowerCase() == 'bike') {
        bikeItem = map;
        break;
      }
    }

    if (bikeItem == null) {
      throw Exception('Bike wash plan not found');
    }

    final inclusivePrice =
        int.tryParse((bikeItem['prices'] ?? '0').toString()) ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final gstPercent =
        int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;
    final exclusivePrice =
        CheckoutPricing.exclusiveAmount(inclusivePrice, gstPercent);

    return BikeWashService(
      id: (bikeItem['id'] ?? '').toString(),
      image: (bikeItem['image'] ?? '').toString(),
      type: (bikeItem['type'] ?? '').toString(),
      price: exclusivePrice.toString(),
      description: (bikeItem['description'] ?? '').toString(),
      displayPrice: inclusivePrice.toString(),
    );
  }
}
