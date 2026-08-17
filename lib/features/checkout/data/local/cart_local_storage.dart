import 'dart:convert';

import 'package:carrocare_flutter/features/checkout/domain/entities/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartLocalStorage {
  static const String _cartKey = 'smart_checkout_cart';

  Future<List<CartItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cartKey);
    if (raw == null || raw.isEmpty) return <CartItem>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <CartItem>[];
    return decoded
        .whereType<Map>()
        .map(
          (item) => CartItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  Future<int> count() async {
    final items = await getItems();
    return items.length;
  }

  Future<Set<String>> vehicleIds() async {
    final items = await getItems();
    return items.map((item) => item.carId).toSet();
  }

  Future<bool> containsVehicle(String vehicleId) async {
    final ids = await vehicleIds();
    return ids.contains(vehicleId);
  }

  bool _isSameItem(CartItem a, CartItem b) {
    return a.carId == b.carId &&
        (a.serviceType == b.serviceType || a.header == b.header) &&
        a.scheduleDate == b.scheduleDate &&
        a.scheduleTime == b.scheduleTime;
  }

  Future<bool> containsVehicleForService({
    required String vehicleId,
    required String serviceHeader,
  }) async {
    final items = await getItems();
    return items.any(
      (entry) =>
          entry.carId == vehicleId &&
          (entry.serviceType == serviceHeader ||
              entry.header == serviceHeader),
    );
  }

  Future<CartItem?> itemForVehicleAndService({
    required String vehicleId,
    required String serviceHeader,
  }) async {
    final items = await getItems();
    for (final CartItem entry in items) {
      if (entry.carId == vehicleId &&
          (entry.serviceType == serviceHeader ||
              entry.header == serviceHeader)) {
        return entry;
      }
    }
    return null;
  }

  Future<bool> upsert(CartItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();
    final updated = <CartItem>[
      ...items.where((entry) => !_isSameItem(entry, item)),
      item,
    ];
    return prefs.setString(
      _cartKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<bool> removeItem(CartItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();
    final updated = items.where((entry) => !_isSameItem(entry, item)).toList();
    return prefs.setString(
      _cartKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<bool> removeByVehicleId(String vehicleId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getItems();
    final updated =
        items.where((entry) => entry.carId != vehicleId).toList(growable: false);
    return prefs.setString(
      _cartKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
}
