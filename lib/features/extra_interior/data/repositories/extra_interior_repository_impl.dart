import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/extra_interior/data/datasources/extra_interior_remote_data_source.dart';
import 'package:carrocare_flutter/features/extra_interior/domain/entities/extra_interior_service.dart';
import 'package:carrocare_flutter/features/extra_interior/domain/repositories/extra_interior_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExtraInteriorRepositoryImpl implements ExtraInteriorRepository {
  ExtraInteriorRepositoryImpl(this._remoteDataSource);

  final ExtraInteriorRemoteDataSource _remoteDataSource;

  @override
  Future<ExtraInteriorService> getExtraInteriorService() async {
    final data = await _remoteDataSource.getExtraInteriorRawResponse();
    final code = (data['code'] ?? '').toString();
    if (code != '200') {
      throw Exception('Invalid response code');
    }

    final rawServices = data['services'];
    if (rawServices is! List) {
      throw Exception('Invalid services payload');
    }

    Map<String, dynamic>? extraInteriorItem;
    for (final item in rawServices) {
      if (item is! Map) continue;
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      final type = (map['type'] ?? '').toString();
      if (type.toLowerCase() == 'extra_interior') {
        extraInteriorItem = map;
        break;
      }
    }

    if (extraInteriorItem == null) {
      throw Exception('Extra interior plan not found');
    }

    final inclusivePrice =
        int.tryParse((extraInteriorItem['prices'] ?? '0').toString()) ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final gstPercent =
        int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;
    final exclusivePrice =
        CheckoutPricing.exclusiveAmount(inclusivePrice, gstPercent);

    return ExtraInteriorService(
      id: (extraInteriorItem['id'] ?? '').toString(),
      image: (extraInteriorItem['image'] ?? '').toString(),
      type: (extraInteriorItem['type'] ?? '').toString(),
      price: exclusivePrice.toString(),
      description: (extraInteriorItem['description'] ?? '').toString(),
      displayPrice: inclusivePrice.toString(),
    );
  }
}
