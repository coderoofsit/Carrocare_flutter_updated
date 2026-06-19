import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/remote_image_with_fallback.dart';
import 'package:carrocare_flutter/features/door_step/data/datasources/door_step_remote_data_source.dart';
import 'package:carrocare_flutter/features/door_step/presentation/services/doorstep_checkout_helper.dart';
import 'package:carrocare_flutter/features/mobile_assets/data/repositories/mobile_assets_repository.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/confirm_form_args.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/door_step_service_item.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/constants/preferred_time_slots.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PagerItem {
  const _PagerItem({
    required this.title,
    required this.imageAsset,
    required this.serviceCardKey,
    required this.action,
  });

  final String title;
  final String imageAsset;
  final String serviceCardKey;
  final String action;
}

class DoorStepServicePage extends StatefulWidget {
  const DoorStepServicePage({super.key});

  @override
  State<DoorStepServicePage> createState() => _DoorStepServicePageState();
}

class _DoorStepServicePageState extends State<DoorStepServicePage> {
  static const List<_PagerItem> _pagerItems = <_PagerItem>[
    _PagerItem(
      title: 'Door step car wash',
      imageAsset: 'assets/images/ds_carwash.png',
      serviceCardKey: 'doorstep_carwash',
      action: 'carwash',
    ),
    _PagerItem(
      title: 'Detailing',
      imageAsset: 'assets/images/ds_detailing.png',
      serviceCardKey: 'doorstep_detailing',
      action: 'detailing',
    ),
    _PagerItem(
      title: 'Painting & Denting',
      imageAsset: 'assets/images/ds_paint.png',
      serviceCardKey: 'doorstep_painting',
      action: 'painting',
    ),
    _PagerItem(
      title: 'Door step insurance',
      imageAsset: 'assets/images/ds_insurance.png',
      serviceCardKey: 'doorstep_insurance',
      action: 'insurance',
    ),
    _PagerItem(
      title: 'Battery change',
      imageAsset: 'assets/images/ds_batterychange.png',
      serviceCardKey: 'doorstep_battery',
      action: 'battery',
    ),
    _PagerItem(
      title: 'Machine polish',
      imageAsset: 'assets/images/ds_detailing.png',
      serviceCardKey: 'doorstep_detailing',
      action: 'machinePolish',
    ),
  ];

  final DoorStepRemoteDataSource _remote =
      DoorStepRemoteDataSource(sl<ApiClient>());
  final DoorstepCheckoutHelper _checkoutHelper = DoorstepCheckoutHelper();
  final VehiclesRepository _vehiclesRepository = sl<VehiclesRepository>();
  final MobileAssetsRepository _mobileAssets = sl<MobileAssetsRepository>();

  GoogleMapController? _mapController;
  LatLng _center = const LatLng(13.085274, 80.170185);
  String _address = '';
  List<VehicleItem> _vehicles = <VehicleItem>[];
  VehicleItem? _selectedVehicle;
  bool _loadingVehicles = true;
  final PageController _pagerController = PageController(viewportFraction: 0.72);

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadVehicles();
    _loadMobileAssets();
  }

  Future<void> _loadMobileAssets() async {
    await _mobileAssets.ensureLoaded();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pagerController.dispose();
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

  Future<void> _openServiceSheet(String action, String title) async {
    if (action == 'insurance') {
      if (!mounted) return;
      context.push(
        '/confirm-form',
        extra: const ConfirmFormArgs(mode: ConfirmFormMode.insurance),
      );
      return;
    }
    if (action == 'machinePolish') {
      if (!mounted) return;
      context.push('/car-polish');
      return;
    }
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a vehicle first')),
      );
      return;
    }
    final category = _selectedVehicle!.category.isNotEmpty
        ? _selectedVehicle!.category
        : _selectedVehicle!.vehicleType;
    try {
      final data = await _remote.getDoorStepServices(
        action: action,
        vehicleCategory: category,
      );
      if ((data['code'] ?? '').toString() != '200') {
        throw Exception((data['message'] ?? 'Failed').toString());
      }
      final raw = data['services'];
      final services = raw is List
          ? raw
              .whereType<Map>()
              .map(
                (e) => DoorStepServiceItem.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .toList()
          : <DoorStepServiceItem>[];
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _DoorStepServiceSheet(
          title: title,
          services: services,
          onBook: (service) => _bookService(service, action),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _bookService(DoorStepServiceItem service, String action) async {
    Navigator.of(context).pop();
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

    final prefs = await SharedPreferences.getInstance();
    final gstPercent =
        int.tryParse(prefs.getString('gst_percentage') ?? '0') ?? 0;
    if (!mounted) return;

    await _checkoutHelper.completeBooking(
      context: context,
      action: action,
      packType: service.service,
      packAmount: service.prices,
      serviceLabel: service.service,
      vehicle: _selectedVehicle!,
      address: _address,
      latitude: '${_center.latitude}',
      longitude: '${_center.longitude}',
      scheduleDate: DateFormat('yyyy-MM-dd').format(date),
      scheduleTime: time,
      gstPercent: gstPercent,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                            _address.isEmpty ? 'Search place' : _address,
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
                if (_loadingVehicles)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _vehicles.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _vehicles.length) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: IconButton(
                              onPressed: () => context.push('/map-add-vehicle'),
                              icon: SvgPicture.asset(
                                'assets/vectors/ic_add_circle.svg',
                                width: 48,
                                height: 48,
                              ),
                            ),
                          );
                        }
                        final vehicle = _vehicles[index];
                        final selected = _selectedVehicle?.id == vehicle.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedVehicle = vehicle),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.15)
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
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pagerController,
                    itemCount: _pagerItems.length,
                    itemBuilder: (context, index) {
                      final item = _pagerItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () =>
                                _openServiceSheet(item.action, item.title),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: RemoteImageWithFallback(
                                      imageUrl: _mobileAssets.serviceCardUrl(
                                        item.serviceCardKey,
                                      ),
                                      fallbackAsset: item.imageAsset,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    item.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

class _DoorStepServiceSheet extends StatefulWidget {
  const _DoorStepServiceSheet({
    required this.title,
    required this.services,
    required this.onBook,
  });

  final String title;
  final List<DoorStepServiceItem> services;
  final void Function(DoorStepServiceItem service) onBook;

  @override
  State<_DoorStepServiceSheet> createState() => _DoorStepServiceSheetState();
}

class _DoorStepServiceSheetState extends State<_DoorStepServiceSheet> {
  final Set<int> _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    var total = 0;
    for (final i in _selected) {
      total += int.tryParse(widget.services[i].prices) ?? 0;
    }
    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: widget.services.length,
              itemBuilder: (context, index) {
                final service = widget.services[index];
                final checked = _selected.contains(index);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (checked) {
                        _selected.remove(index);
                      } else {
                        _selected.add(index);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: checked ? AppColors.primary : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Image.network(
                            service.image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/placeholder.png',
                            ),
                          ),
                        ),
                        Text(
                          service.service,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('₹ ${service.prices}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Text(
                  'Total: ₹ $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selected.isEmpty
                      ? null
                      : () => widget.onBook(widget.services[_selected.first]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Proceed'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
