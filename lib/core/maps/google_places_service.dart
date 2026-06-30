import 'package:carrocare_flutter/core/maps/google_maps_api_keys.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;
}

class PlaceDetailsResult {
  const PlaceDetailsResult({
    required this.latLng,
    required this.address,
  });

  final LatLng latLng;
  final String address;
}

class GooglePlacesService {
  GooglePlacesService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    LatLng? bias,
  }) async {
    final query = input.trim();
    if (query.length < 2) return const <PlaceSuggestion>[];

    final params = <String, dynamic>{
      'input': query,
      'key': GoogleMapsApiKeys.current,
      'components': 'country:in',
      'language': 'en',
    };
    if (bias != null) {
      params['location'] = '${bias.latitude},${bias.longitude}';
      params['radius'] = 50000;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      queryParameters: params,
    );

    final data = response.data;
    if (data == null || data['status'] != 'OK') {
      return const <PlaceSuggestion>[];
    }

    final predictions = data['predictions'];
    if (predictions is! List) return const <PlaceSuggestion>[];

    return predictions
        .whereType<Map>()
        .map((raw) {
          final map = raw.map((key, value) => MapEntry(key.toString(), value));
          final structured = map['structured_formatting'];
          final formatting = structured is Map
              ? structured.map(
                  (key, value) => MapEntry(key.toString(), value),
                )
              : const <String, dynamic>{};
          return PlaceSuggestion(
            placeId: (map['place_id'] ?? '').toString(),
            description: (map['description'] ?? '').toString(),
            mainText: (formatting['main_text'] ?? map['description'] ?? '')
                .toString(),
            secondaryText: (formatting['secondary_text'] ?? '').toString(),
          );
        })
        .where((item) => item.placeId.isNotEmpty && item.description.isNotEmpty)
        .toList();
  }

  Future<PlaceDetailsResult?> placeDetails(String placeId) async {
    if (placeId.trim().isEmpty) return null;

    final response = await _dio.get<Map<String, dynamic>>(
      'https://maps.googleapis.com/maps/api/place/details/json',
      queryParameters: <String, dynamic>{
        'place_id': placeId,
        'fields': 'geometry/location,formatted_address',
        'key': GoogleMapsApiKeys.current,
      },
    );

    final data = response.data;
    if (data == null || data['status'] != 'OK') return null;

    final result = data['result'];
    if (result is! Map) return null;
    final resultMap = result.map((key, value) => MapEntry(key.toString(), value));

    final geometry = resultMap['geometry'];
    if (geometry is! Map) return null;
    final geometryMap =
        geometry.map((key, value) => MapEntry(key.toString(), value));
    final location = geometryMap['location'];
    if (location is! Map) return null;
    final locationMap =
        location.map((key, value) => MapEntry(key.toString(), value));

    final lat = locationMap['lat'];
    final lng = locationMap['lng'];
    if (lat is! num || lng is! num) return null;

    return PlaceDetailsResult(
      latLng: LatLng(lat.toDouble(), lng.toDouble()),
      address: (resultMap['formatted_address'] ?? '').toString(),
    );
  }
}
