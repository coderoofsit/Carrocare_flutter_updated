import 'dart:convert';

import 'package:carrocare_flutter/features/mobile_assets/data/datasources/mobile_assets_remote_data_source.dart';
import 'package:carrocare_flutter/core/widgets/remote_image_with_fallback.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileAssetsRepository {
  MobileAssetsRepository(this._remote);

  static const String _cacheKey = 'mobile_assets_cache_v1';
  static const Duration _cacheTtl = Duration(hours: 1);

  final MobileAssetsRemoteDataSource _remote;

  List<String> _homeBannerUrls = <String>[];
  List<String> _onboardingUrls = <String>[];
  Map<String, String> _serviceCards = <String, String>{};
  bool _loaded = false;

  List<String> get homeBannerUrls => List<String>.unmodifiable(_homeBannerUrls);
  List<String> get onboardingUrls => List<String>.unmodifiable(_onboardingUrls);

  String? serviceCardUrl(String key) => _serviceCards[key];

  bool get isLoaded => _loaded;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await _loadFromPrefs();
    if (_loaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final data = await _remote.fetchMobileAssets();
      _applyPayload(data);
      _loaded = true;
      await _saveToPrefs(data);
    } catch (_) {
      if (!_loaded) {
        await _loadFromPrefs();
      }
    }
  }

  void _applyPayload(Map<String, dynamic> data) {
    _homeBannerUrls = _parseUrlList(data['home_banners']);
    _onboardingUrls = _parseUrlList(data['onboarding_slides']);
    final rawCards = data['service_cards'];
    if (rawCards is Map) {
      _serviceCards = rawCards.map(
        (key, value) => MapEntry('$key', '$value'),
      );
    } else {
      _serviceCards = <String, String>{};
    }
  }

  List<String> _parseUrlList(dynamic raw) {
    if (raw is! List) return <String>[];
    final List<MapEntry<int, String>> entries = <MapEntry<int, String>>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is Map) {
        final url = '${item['url'] ?? ''}'.trim();
        if (url.isNotEmpty) {
          final order = int.tryParse('${item['sort_order'] ?? i}') ?? i;
          entries.add(MapEntry(order, url));
        }
      }
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => e.value).toList();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse('${decoded['cached_at'] ?? ''}');
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > _cacheTtl) {
        return;
      }
      _applyPayload(decoded);
      _loaded = true;
    } catch (_) {
      return;
    }
  }

  Future<void> _saveToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = Map<String, dynamic>.from(data)
      ..['cached_at'] = DateTime.now().toIso8601String();
    await prefs.setString(_cacheKey, jsonEncode(payload));
  }

  List<RemoteSlide> mergeSlides({
    required List<String> apiUrls,
    required List<String> fallbackAssets,
  }) {
    final int length = apiUrls.length > fallbackAssets.length
        ? apiUrls.length
        : fallbackAssets.length;
    if (length == 0) return <RemoteSlide>[];
    return List<RemoteSlide>.generate(length, (int index) {
      final String fallback = index < fallbackAssets.length
          ? fallbackAssets[index]
          : fallbackAssets.last;
      final String? url = index < apiUrls.length ? apiUrls[index] : null;
      return RemoteSlide(imageUrl: url, fallbackAsset: fallback);
    });
  }

  List<RemoteSlide> homeBannerSlides(List<String> fallbackAssets) {
    return mergeSlides(apiUrls: _homeBannerUrls, fallbackAssets: fallbackAssets);
  }

  List<RemoteSlide> onboardingSlides(List<String> fallbackAssets) {
    return mergeSlides(apiUrls: _onboardingUrls, fallbackAssets: fallbackAssets);
  }
}
