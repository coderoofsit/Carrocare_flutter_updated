import 'package:carrocare_flutter/core/storage/map_location_store.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
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
  GoogleMapController? _mapController;
  LatLng _position = const LatLng(13.085274, 80.170185);
  String _addressLabel = '';
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final lat = await _store.readLatitude();
    final lng = await _store.readLongitude();
    final address = await _store.readAddress();
    if (lat != null && lng != null) {
      setState(() {
        _position = LatLng(lat, lng);
        _addressLabel = address;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_position));
    } else {
      await _moveToCurrentLocation();
    }
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
        setState(() {
          _addressLabel = parts.join(', ');
        });
      } else {
        setState(() {
          _addressLabel =
              '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
        });
      }
    } catch (_) {
      setState(() {
        _addressLabel =
            '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
      });
    } finally {
      if (mounted) setState(() => _loadingAddress = false);
    }
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
      body: Stack(
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
            onTap: (latLng) {
              setState(() => _position = latLng);
              _reverseGeocode(latLng);
            },
            onLongPress: (latLng) {
              setState(() => _position = latLng);
              _reverseGeocode(latLng);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          SafeArea(
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 35,
                    height: 35,
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(5),
                    color: Colors.white70,
                    child: Image.asset('assets/images/back.png'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.white,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    _loadingAddress ? 'Loading address...' : _addressLabel,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _updateLocation,
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
          ),
        ],
      ),
    );
  }
}
