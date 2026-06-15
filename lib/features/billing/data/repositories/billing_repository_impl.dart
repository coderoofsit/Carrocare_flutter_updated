import 'package:carrocare_flutter/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:carrocare_flutter/features/billing/domain/entities/billing_item.dart';
import 'package:carrocare_flutter/features/billing/domain/repositories/billing_repository.dart';

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._remoteDataSource);

  final BillingRemoteDataSource _remoteDataSource;

  @override
  Future<List<BillingItem>> getBillings({
    required String token,
    required String customerId,
  }) async {
    if (token.isEmpty || customerId.isEmpty) {
      throw Exception('Session missing. Please login again.');
    }
    final data = await _remoteDataSource.getBillings(
      token: token,
      customerId: customerId,
    );
    final code = (data['code'] ?? '').toString();
    if (code == '203') {
      throw Exception('Session expired');
    }
    if (code == '201') {
      return <BillingItem>[];
    }
    if (code != '200') {
      throw Exception((data['message'] ?? 'Failed to load billings').toString());
    }
    final list = data['res'];
    if (list is! List) return <BillingItem>[];

    final parsed = <BillingItem>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      try {
        parsed.add(
          BillingItem.fromJson(
            raw.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return parsed;
  }
}
