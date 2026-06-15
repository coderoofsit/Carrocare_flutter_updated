import 'package:carrocare_flutter/features/billing/domain/entities/billing_item.dart';

abstract class BillingRepository {
  Future<List<BillingItem>> getBillings({
    required String token,
    required String customerId,
  });
}
