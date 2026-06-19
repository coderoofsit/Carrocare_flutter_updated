import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/doorstep_book_args.dart';
import 'package:carrocare_flutter/features/door_step/presentation/services/doorstep_checkout_helper.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/constants/preferred_time_slots.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Map + vehicle selection for a single priced doorstep booking (e.g. machine polish).
class DoorstepBookPage extends StatefulWidget {
  const DoorstepBookPage({super.key, required this.args});

  final DoorstepBookArgs args;

  @override
  State<DoorstepBookPage> createState() => _DoorstepBookPageState();
}

class _DoorstepBookPageState extends State<DoorstepBookPage> {
  final VehiclesRepository _vehiclesRepository = sl<VehiclesRepository>();
  final DoorstepCheckoutHelper _checkoutHelper = DoorstepCheckoutHelper();

  GoogleMapController? _mapController;
  LatLng _center = const LatLng(13.085274, 80.170185);
  String _address = '';
  List<VehicleItem> _vehicles = <VehicleItem>[];
  VehicleItem? _selectedVehicle;
  bool _loadingVehicles = true;
  bool _booking = false;
  int _gstPercent = 0;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadVehicles();
    _loadGst();
  }

  Future<void> _loadGst() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _gstPercent =
          int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _address = '${position.latitude}, ${position.longitude}';
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    } catch (_) {}
  }

  Future<void> _loadVehicles() async {
    setState(() => _loadingVehicles = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      final list = await _vehiclesRepository.getMyVehicles(
        token: prefs.getString('token') ?? '',
        customerId: prefs.getString('customer_id') ?? '',
      );
      if (!mounted) return;
      setState(() {
        _vehicles = list;
        _selectedVehicle = list.isNotEmpty ? list.first : null;
        _loadingVehicles = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _book() async {
    if (_booking) return;
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a vehicle first')),
      );
      return;
    }
    if (_address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service location')),
      );
      return;
    }
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: kInternalWashPreferredTimes
            .map(
              (slot) => ListTile(
                title: Text(slot),
                onTap: () => Navigator.pop(context, slot),
              ),
            )
            .toList(),
      ),
    );
    if (time == null || !mounted) return;
    setState(() => _booking = true);
    try {
      await _checkoutHelper.completeBooking(
        context: context,
        action: widget.args.action,
        packType: widget.args.packType,
        packAmount: widget.args.packAmount,
        serviceLabel: widget.args.serviceLabel,
        vehicle: _selectedVehicle!,
        address: _address,
        latitude: '${_center.latitude}',
        longitude: '${_center.longitude}',
        scheduleDate: DateFormat('yyyy-MM-dd').format(date),
        scheduleTime: time,
        gstPercent: _gstPercent,
      );
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = int.tryParse(widget.args.packAmount) ?? 0;
    final gstAmount = (price * _gstPercent) ~/ 100;
    final total = price + gstAmount;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 14),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (c) => _mapController = c,
            onTap: (latLng) {
              setState(() {
                _center = latLng;
                _address = '${latLng.latitude}, ${latLng.longitude}';
              });
            },
          ),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Image.asset(
                          'assets/images/menu.png',
                          width: 22,
                          color: AppColors.white,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            _address.isEmpty ? 'Tap map to set location' : _address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _initLocation,
                        icon: const Icon(Icons.my_location, color: AppColors.white),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        widget.args.serviceLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total (incl. GST): ₹ $total',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingVehicles)
                        const LinearProgressIndicator(minHeight: 2)
                      else
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _vehicles.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _vehicles.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: IconButton(
                                    onPressed: () =>
                                        context.push('/map-add-vehicle'),
                                    icon: SvgPicture.asset(
                                      'assets/vectors/ic_add_circle.svg',
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                );
                              }
                              final vehicle = _vehicles[index];
                              final selected =
                                  _selectedVehicle?.id == vehicle.id;
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _selectedVehicle = vehicle,
                                ),
                                child: Container(
                                  width: 120,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.15)
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        vehicle.vehicleNo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        vehicle.model,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _booking ? null : _book,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _booking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Text('Confirm Booking'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
