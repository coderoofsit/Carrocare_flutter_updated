import 'dart:async';

import 'package:carrocare_flutter/core/maps/google_places_service.dart';
import 'package:carrocare_flutter/core/storage/map_location_store.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/map/domain/entities/map_location_result.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Matches Android [LocateOnMapActivity].
class LocateOnMapPage extends StatefulWidget {
  const LocateOnMapPage({super.key});

  @override
  State<LocateOnMapPage> createState() => _LocateOnMapPageState();
}

class _LocateOnMapPageState extends State<LocateOnMapPage> {
  final MapLocationStore _store = MapLocationStore();
  final GooglePlacesService _placesService = GooglePlacesService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  GoogleMapController? _mapController;
  Timer? _searchDebounce;
  LatLng _position = const LatLng(13.085274, 80.170185);
  String _addressLabel = '';
  bool _loadingAddress = false;
  bool _searchingPlaces = false;
  List<PlaceSuggestion> _searchSuggestions = <PlaceSuggestion>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchFieldChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchFieldChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    final lat = await _store.readLatitude();
    final lng = await _store.readLongitude();
    final address = await _store.readAddress();
    if (lat != null && lng != null) {
      setState(() {
        _position = LatLng(lat, lng);
        _addressLabel = address;
        if (address.isNotEmpty) {
          _searchController.text = address;
        }
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_position));
    } else {
      await _moveToCurrentLocation();
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _searchSuggestions = <PlaceSuggestion>[];
        _searchingPlaces = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchPlaceSuggestions(trimmed);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    setState(() => _searchingPlaces = true);
    try {
      final results = await _placesService.autocomplete(
        query,
        bias: _position,
      );
      if (!mounted) return;
      setState(() {
        _searchSuggestions = results;
        _searchingPlaces = false;
      });
      if (results.isEmpty) {
        _showMessage('No places found. Try a different search.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchSuggestions = <PlaceSuggestion>[];
        _searchingPlaces = false;
      });
      _showMessage('Unable to search places. Please try again.');
    }
  }

  Future<void> _selectPlaceSuggestion(PlaceSuggestion suggestion) async {
    _searchFocus.unfocus();
    setState(() {
      _searchSuggestions = <PlaceSuggestion>[];
      _searchController.text = suggestion.description;
    });

    final details = await _placesService.placeDetails(suggestion.placeId);
    if (!mounted) return;
    if (details == null) {
      _showMessage('Unable to load place details. Please try again.');
      return;
    }

    final latLng = details.latLng;
    setState(() {
      _position = latLng;
      _addressLabel = details.address.isNotEmpty
          ? details.address
          : suggestion.description;
      _searchController.text = _addressLabel;
    });
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchSuggestions = <PlaceSuggestion>[];
      _searchingPlaces = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _position = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      await _reverseGeocode(latLng);
    } catch (_) {}
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    setState(() => _loadingAddress = true);
    try {
      final places = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (places.isNotEmpty) {
        final p = places.first;
        final parts = <String>[
          if ((p.street ?? '').isNotEmpty) p.street!,
          if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
          if ((p.locality ?? '').isNotEmpty) p.locality!,
          if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
          if ((p.postalCode ?? '').isNotEmpty) p.postalCode!,
        ];
        final label = parts.join(', ');
        setState(() => _addressLabel = label);
        if (!_searchFocus.hasFocus) {
          _searchController.text = label;
        }
      } else {
        final label =
            '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
        setState(() => _addressLabel = label);
        if (!_searchFocus.hasFocus) {
          _searchController.text = label;
        }
      }
    } catch (_) {
      final label =
          '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
      setState(() => _addressLabel = label);
      if (!_searchFocus.hasFocus) {
        _searchController.text = label;
      }
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
  }

  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _position = latLng;
      _searchSuggestions = <PlaceSuggestion>[];
    });
    await _reverseGeocode(latLng);
  }

  Future<void> _updateLocation() async {
    await _store.savePick(
      address: _addressLabel,
      latitude: _position.latitude,
      longitude: _position.longitude,
    );
    if (!mounted) return;
    context.pop(
      MapLocationResult(
        address: _addressLabel,
        latitude: _position.latitude,
        longitude: _position.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: <Widget>[
                  Material(
                    color: AppColors.white,
                    elevation: 3,
                    shadowColor: AppColors.shadowMedium,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/back.png',
                          color: AppColors.grey800,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select location',
                      style: AppTypography.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Material(
                elevation: 2,
                shadowColor: AppColors.shadowLight,
                borderRadius: BorderRadius.circular(12),
                color: AppColors.white,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    if (_searchSuggestions.isNotEmpty) {
                      _selectPlaceSuggestion(_searchSuggestions.first);
                    } else if (value.trim().length >= 2) {
                      _fetchPlaceSuggestions(value.trim());
                    }
                  },
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.grey800,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search area, street, or place name',
                    hintStyle: AppTypography.dmSans(
                      fontSize: 14,
                      color: AppColors.grey500,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    suffixIcon: _searchingPlaces
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: _clearSearch,
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.grey600,
                                  size: 20,
                                ),
                              )
                            : null),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            if (_searchSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey200),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _searchSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: AppColors.grey200,
                  ),
                  itemBuilder: (context, index) {
                    final suggestion = _searchSuggestions[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      leading: const Icon(
                        Icons.place_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      title: Text(
                        suggestion.mainText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey800,
                        ),
                      ),
                      subtitle: suggestion.secondaryText.isEmpty
                          ? null
                          : Text(
                              suggestion.secondaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.dmSans(
                                fontSize: 12,
                                color: AppColors.grey600,
                              ),
                            ),
                      onTap: () => _selectPlaceSuggestion(suggestion),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: <Widget>[
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _position,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        markers: <Marker>{
                          Marker(
                            markerId: const MarkerId('pick'),
                            position: _position,
                            draggable: true,
                            onDragEnd: (latLng) {
                              setState(() => _position = latLng);
                              _reverseGeocode(latLng);
                            },
                          ),
                        },
                        onTap: _onMapTap,
                        onLongPress: _onMapTap,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          color: AppColors.white,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: IconButton(
                            onPressed: _moveToCurrentLocation,
                            icon: const Icon(
                              Icons.my_location,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _loadingAddress
                        ? 'Loading address...'
                        : (_addressLabel.isEmpty
                            ? 'Tap map or search to set location'
                            : _addressLabel),
                    style: AppTypography.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addressLabel.isEmpty ? null : _updateLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Update location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
