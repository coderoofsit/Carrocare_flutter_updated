import 'package:shared_preferences/shared_preferences.dart';

/// Persists map pick results (Android SessionManager parity).
class MapLocationStore {
  static const String mapAddress = 'map_address';
  static const String mapLatitude = 'map_latitude';
  static const String mapLongitude = 'map_longitude';
  static const String keyAddress = 'address';
  static const String keyLatitude = 'latitude';
  static const String keyLongitude = 'longitude';

  Future<void> savePick({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAddress, address);
    await prefs.setString(keyLatitude, latitude.toString());
    await prefs.setString(keyLongitude, longitude.toString());
    await prefs.setString(mapAddress, address);
    await prefs.setString(mapLatitude, latitude.toString());
    await prefs.setString(mapLongitude, longitude.toString());
  }

  Future<String> readAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAddress) ??
        prefs.getString(mapAddress) ??
        '';
  }

  Future<double?> readLatitude() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(keyLatitude) ?? prefs.getString(mapLatitude) ?? '';
    return double.tryParse(raw);
  }

  Future<double?> readLongitude() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(keyLongitude) ?? prefs.getString(mapLongitude) ?? '';
    return double.tryParse(raw);
  }
}
