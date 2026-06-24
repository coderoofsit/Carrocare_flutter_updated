import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_gst_config.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_pricing.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/razorpay_price_summary.dart';
import 'package:carrocare_flutter/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/checkout_navigation.dart';
import 'package:carrocare_flutter/features/checkout/presentation/services/razorpay_checkout_service.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/razorpay_price_summary_sheet.dart';
import 'package:carrocare_flutter/features/door_step/data/datasources/door_step_remote_data_source.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/doorstep_package.dart';
import 'package:carrocare_flutter/features/door_step/domain/entities/doorstep_payment_mode.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/constants/preferred_time_slots.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DoorstepDraft {
  const _DoorstepDraft({
    required this.date,
    required this.timeSlot,
    required this.paymentMode,
    required this.addOns,
  });

  final DateTime date;
  final String timeSlot;
  final DoorstepPaymentMode paymentMode;
  final List<DoorstepAddOn> addOns;
}

class _DoorstepServiceImage extends StatelessWidget {
  const _DoorstepServiceImage({
    required this.imageUrl,
    required this.fallbackAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final String? imageUrl;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = imageUrl != null && imageUrl!.isNotEmpty
        ? Image.network(
            imageUrl!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) => Image.asset(
              fallbackAsset,
              width: width,
              height: height,
              fit: fit,
            ),
          )
        : Image.asset(
            fallbackAsset,
            width: width,
            height: height,
            fit: fit,
          );
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class DoorStepServicePage extends StatefulWidget {
  const DoorStepServicePage({super.key});

  @override
  State<DoorStepServicePage> createState() => _DoorStepServicePageState();
}

class _DoorStepServicePageState extends State<DoorStepServicePage> {
  final DoorStepRemoteDataSource _remote =
      DoorStepRemoteDataSource(sl<ApiClient>());
  final VehiclesRepository _vehiclesRepository = sl<VehiclesRepository>();
  final RazorpayCheckoutService _razorpay = RazorpayCheckoutService();

  bool _placingOrder = false;
  bool _loadingVehicles = true;
  bool _loadingPackages = true;
  String? _packagesError;
  List<VehicleItem> _vehicles = <VehicleItem>[];
  VehicleItem? _selectedVehicle;
  List<DoorstepPackage> _packages = <DoorstepPackage>[];
  List<DoorstepCategoryTab> _tabs = const <DoorstepCategoryTab>[
    DoorstepCategoryTab(
      label: 'All',
      category: DoorstepCatalogCategory.all,
      imageUrl: null,
      fallbackAsset: 'assets/images/app_icon_512.png',
    ),
  ];
  DoorstepCatalogCategory _selectedCatalog = DoorstepCatalogCategory.all;
  double? _latitude;
  double? _longitude;
  String _currentLocationLabel = '';

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadVehicles();
    _loadPackages();
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  List<DoorstepPackage> get _visiblePackages {
    if (_selectedCatalog == DoorstepCatalogCategory.all) {
      return _packages;
    }
    return _packages
        .where((package) => package.category == _selectedCatalog)
        .toList();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _loadingPackages = true;
      _packagesError = null;
    });
    try {
      final response = await _remote.getDoorstepPackages();
      if (!mounted) return;
      setState(() {
        _packages = response.packages;
        if (response.tabs.isNotEmpty) {
          _tabs = response.tabs;
        }
        _loadingPackages = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPackages = false;
        _packagesError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _orderMessage(Map<String, dynamic> data) {
    final code = (data['code'] ?? '').toString();
    if (code == '200' ||
        (data['message'] ?? '').toString().toLowerCase() == 'success' ||
        (data['status'] ?? '').toString().toLowerCase() == 'success') {
      return (data['result'] ?? data['message'] ?? 'Order placed successfully')
          .toString();
    }
    throw Exception(
      (data['result'] ?? data['message'] ?? 'Order failed').toString(),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _currentLocationLabel =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      });
    } catch (_) {}
  }

  Future<void> _loadVehicles({bool isRefresh = false}) async {
    final showSectionLoader = !isRefresh && _vehicles.isEmpty;
    if (showSectionLoader) {
      setState(() => _loadingVehicles = true);
    }
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
      if (!mounted) return;
      setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait(<Future<void>>[
      _loadVehicles(isRefresh: true),
      _loadPackages(),
    ]);
  }

  String _vehicleDisplayName(VehicleItem vehicle) {
    final model = vehicle.model.trim();
    final make = vehicle.make.trim();
    if (make.isEmpty && model.isEmpty) {
      return vehicle.vehicleNo;
    }
    if (make.isEmpty) return model;
    if (model.isEmpty) return make;
    return '$make $model';
  }

  String _vehicleCategoryChip(VehicleItem vehicle) {
    final value = vehicle.category.trim().isNotEmpty
        ? vehicle.category.trim()
        : vehicle.vehicleType.trim();
    return value.isEmpty ? 'Vehicle' : value;
  }

  String _bookingAddressForVehicle(VehicleItem vehicle) {
    final parts = <String>[
      vehicle.apartmentName,
      vehicle.parkingArea,
      vehicle.parkingLotNo,
    ].where((value) => value.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    if (_currentLocationLabel.isNotEmpty) {
      return _currentLocationLabel;
    }
    return 'Current doorstep location will be confirmed before service.';
  }

  Future<void> _startBookingFlow(DoorstepPackage package) async {
    if (_selectedVehicle == null) {
      _showMessage('Please add a vehicle first');
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PackageDetailSheet(
        package: package,
        vehicle: _selectedVehicle!,
        address: _bookingAddressForVehicle(_selectedVehicle!),
      ),
    );
    if (confirmed != true || !mounted) return;

    final addOns =
        await showModalBottomSheet<List<DoorstepAddOn>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _AddOnSheet(package: package),
        ) ??
        <DoorstepAddOn>[];
    if (!mounted) return;

    final draft = await showModalBottomSheet<_DoorstepDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsSheet(
        package: package,
        addOns: addOns,
        vehicle: _selectedVehicle!,
      ),
    );
    if (draft == null || !mounted) return;

    final shouldSubmit = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderPreviewSheet(
        package: package,
        draft: draft,
        vehicle: _selectedVehicle!,
        address: _bookingAddressForVehicle(_selectedVehicle!),
      ),
    );
    if (shouldSubmit != true || !mounted) return;

    await _submitOrder(package, draft);
  }

  Future<void> _submitOrder(DoorstepPackage package, _DoorstepDraft draft) async {
    if (_placingOrder || _selectedVehicle == null) return;

    final prefs = await SharedPreferences.getInstance();
    final gstPercent = CheckoutGstConfig.resolvePercent(prefs);
  final addOnTotal = draft.addOns.fold<int>(
      0,
      (sum, addOn) => sum + addOn.price,
    );
    final inclusiveTotal = package.price + addOnTotal;
    final breakdown = CheckoutPricing.breakdownFromInclusive(
      inclusiveTotal,
      gstPercent,
    );
    final serviceNames = <String>[
      package.name,
      ...draft.addOns.map((addOn) => addOn.title),
    ];
    final scheduleDate = DateFormat('yyyy-MM-dd').format(draft.date);
    final serviceType = package.categoryLabel;
    final orderFields = <String, String>{
      'customerId': prefs.getString('customer_id') ?? '',
      'token': prefs.getString('token') ?? '',
      'packType': serviceNames.join(' + '),
      'packAmount': '$inclusiveTotal',
      'vehicleId': _selectedVehicle!.id,
      'serviceType': serviceType,
      'subTotal': '${breakdown.subTotal}',
      'gst': '$gstPercent',
      'gstAmount': '${breakdown.gstAmount}',
      'totalAmount': '${breakdown.total}',
      'scheduleDate': scheduleDate,
      'scheduleTime': draft.timeSlot,
      'address': _bookingAddressForVehicle(_selectedVehicle!),
      'latitude': '${_latitude ?? 0}',
      'longitude': '${_longitude ?? 0}',
    };

    setState(() => _placingOrder = true);
    try {
      if (draft.paymentMode == DoorstepPaymentMode.cod) {
        final data = await _remote.saveDoorstepCodOrder(
          customerId: orderFields['customerId']!,
          token: orderFields['token']!,
          packType: orderFields['packType']!,
          packAmount: orderFields['packAmount']!,
          vehicleId: orderFields['vehicleId']!,
          serviceType: orderFields['serviceType']!,
          subTotal: orderFields['subTotal']!,
          gst: orderFields['gst']!,
          gstAmount: orderFields['gstAmount']!,
          totalAmount: orderFields['totalAmount']!,
          scheduleDate: orderFields['scheduleDate']!,
          scheduleTime: orderFields['scheduleTime']!,
          address: orderFields['address']!,
          latitude: orderFields['latitude']!,
          longitude: orderFields['longitude']!,
        );
        if (!mounted) return;
        _showMessage(_orderMessage(data));
        return;
      }

      final email = prefs.getString('email') ?? '';
      final mobile =
          prefs.getString('mobile') ?? prefs.getString('usermobile') ?? '';
      final priceSummary = RazorpayPriceSummary.fromInclusive(
        serviceLabel: serviceType,
        inclusiveTotal: inclusiveTotal,
        gstPercent: gstPercent,
      );
      final router = GoRouter.of(context);
      final confirmed = await showRazorpayPriceSummarySheet(
        context: context,
        summary: priceSummary,
        onConfirmPay: () async {
          final keys = await sl<CheckoutRepository>().getRazorpayKeys();
          if (!mounted) return;
          final paymentId = await _razorpay.openAndWait(
            keyId: keys.keyId,
            amountPaise: breakdown.total * 100,
            description: orderFields['packType']!,
            email: email,
            contact: mobile,
            priceSummary: priceSummary,
          );
          final data = await _remote.saveDoorstepOnlineOrder(
            paymentId: paymentId,
            customerId: orderFields['customerId']!,
            token: orderFields['token']!,
            packType: orderFields['packType']!,
            packAmount: orderFields['packAmount']!,
            vehicleId: orderFields['vehicleId']!,
            serviceType: orderFields['serviceType']!,
            subTotal: orderFields['subTotal']!,
            gst: orderFields['gst']!,
            gstAmount: orderFields['gstAmount']!,
            totalAmount: orderFields['totalAmount']!,
            scheduleDate: orderFields['scheduleDate']!,
            scheduleTime: orderFields['scheduleTime']!,
            address: orderFields['address']!,
            latitude: orderFields['latitude']!,
            longitude: orderFields['longitude']!,
          );
          _orderMessage(data);
        },
      );
      if (!mounted) return;
      if (confirmed) {
        goToPaymentSuccess(router);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _placingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Doorstep Services',
      subtitle: _selectedVehicle == null
          ? 'Select a vehicle to continue'
          : _vehicleDisplayName(_selectedVehicle!),
      onBack: () => context.pop(),
      backgroundDecoration: const BoxDecoration(
        gradient: AppGradients.washScreenBackground,
      ),
      body: Column(
        children: <Widget>[
          if (_placingOrder) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                children: <Widget>[
                  _buildVehicleSection(),
                  const SizedBox(height: 16),
                  _buildCategorySection(),
                  const SizedBox(height: 16),
                  Text(
                    'Available Packages',
                    style: AppTypography.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a package to view details and book.',
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingPackages)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      ),
                    )
                  else if (_packagesError != null)
                    _SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Unable to load packages',
                            style: AppTypography.quicksand(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _packagesError!,
                            style: AppTypography.dmSans(
                              fontSize: 13,
                              color: AppColors.grey600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: _loadPackages,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_visiblePackages.isEmpty)
                    _SoftCard(
                      child: Text(
                        'No packages available in this category right now.',
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          color: AppColors.grey600,
                        ),
                      ),
                    )
                  else
                    ..._visiblePackages.map(
                    (package) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PackageCard(
                        package: package,
                        onTap: () => _startBookingFlow(package),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    if (_loadingVehicles && _vehicles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return _SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No vehicle added yet',
              style: AppTypography.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a vehicle to start the new doorstep booking flow.',
              style: AppTypography.dmSans(
                fontSize: 13,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => context.push('/map-add-vehicle'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Add Vehicle'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Select Vehicle',
                style: AppTypography.quicksand(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/map-add-vehicle'),
              child: const Text('Add Vehicle'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final vehicle = _vehicles[index];
              final isSelected = vehicle.id == _selectedVehicle?.id;
              return _VehicleCard(
                vehicle: vehicle,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedVehicle = vehicle),
                titleBuilder: _vehicleDisplayName,
                chipBuilder: _vehicleCategoryChip,
              );
            },
          ),
        ),
        if (_selectedVehicle != null) ...<Widget>[
          const SizedBox(height: 12),
          _SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _vehicleDisplayName(_selectedVehicle!),
                        style: AppTypography.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                        ),
                      ),
                    ),
                    _ChipPill(label: _vehicleCategoryChip(_selectedVehicle!)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedVehicle!.vehicleNo,
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _bookingAddressForVehicle(_selectedVehicle!),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: AppColors.grey600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Service Categories',
          style: AppTypography.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              return _CategoryTile(
                tab: tab,
                selected: tab.category == _selectedCatalog,
                onTap: () => setState(() => _selectedCatalog = tab.category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
    required this.titleBuilder,
    required this.chipBuilder,
  });

  final VehicleItem vehicle;
  final bool isSelected;
  final VoidCallback onTap;
  final String Function(VehicleItem vehicle) titleBuilder;
  final String Function(VehicleItem vehicle) chipBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 104,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 176,
          height: 104,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.grey200,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.white.withValues(alpha: 0.16)
                          : AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      size: 16,
                      color: isSelected ? AppColors.white : AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  _ChipPill(
                    label: chipBuilder(vehicle),
                    ellipsize: false,
                    backgroundColor: isSelected
                        ? AppColors.white.withValues(alpha: 0.16)
                        : AppColors.primaryTint,
                    foregroundColor:
                        isSelected ? AppColors.white : AppColors.grey800,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                titleBuilder(vehicle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.quicksand(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.white : AppColors.grey800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                vehicle.vehicleNo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.dmSans(
                  fontSize: 11,
                  color: isSelected
                      ? AppColors.white.withValues(alpha: 0.82)
                      : AppColors.grey600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final DoorstepCategoryTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 100,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 78,
          height: 100,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? AppColors.white : AppColors.grey100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            boxShadow: selected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _DoorstepServiceImage(
                    imageUrl: tab.imageUrl,
                    fallbackAsset: tab.fallbackAsset,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tab.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.dmSans(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.grey800 : AppColors.grey700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.onTap,
  });

  final DoorstepPackage package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _DoorstepServiceImage(
                  imageUrl: package.imageUrl,
                  fallbackAsset: package.fallbackAsset,
                  width: 84,
                  height: 84,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      package.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                        height: 1.15,
                      ),
                    ),
                    if (package.badge != null) ...<Widget>[
                      const SizedBox(height: 3),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ChipPill(
                          label: package.badge!,
                          backgroundColor: AppColors.primaryTint,
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      package.categoryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package.bullets
                          .take(2)
                          .map((value) => '• $value')
                          .join('\n'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.dmSans(
                        fontSize: 10,
                        color: AppColors.grey600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Text(
                          '₹${package.price}',
                          style: AppTypography.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'Book Now',
                            style: AppTypography.quicksand(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageDetailSheet extends StatelessWidget {
  const _PackageDetailSheet({
    required this.package,
    required this.vehicle,
    required this.address,
  });

  final DoorstepPackage package;
  final VehicleItem vehicle;
  final String address;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SheetHandleAndClose(
              title: package.name,
              onClose: () => Navigator.pop(context),
            ),
            Text(
              package.shortDescription,
              style: AppTypography.dmSans(
                fontSize: 14,
                color: AppColors.grey600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ...package.bullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircleAvatar(radius: 3, backgroundColor: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.dmSans(
                          fontSize: 15,
                          color: AppColors.grey700,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (package.note != null) ...<Widget>[
              const SizedBox(height: 4),
              _InfoBanner(text: package.note!),
            ],
            const SizedBox(height: 18),
            _SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${vehicle.make} ${vehicle.model}'.trim(),
                    style: AppTypography.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address,
                    style: AppTypography.dmSans(
                      fontSize: 14,
                      color: AppColors.grey600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Amount Payable ₹${package.price}',
              style: AppTypography.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: AppTypography.quicksand(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOnSheet extends StatefulWidget {
  const _AddOnSheet({required this.package});

  final DoorstepPackage package;

  @override
  State<_AddOnSheet> createState() => _AddOnSheetState();
}

class _AddOnSheetState extends State<_AddOnSheet> {
  final Set<int> _selected = <int>{};

  @override
  Widget build(BuildContext context) {
    final addOnTotal = _selected.fold<int>(
      0,
      (sum, index) => sum + widget.package.addOns[index].price,
    );
    final inclusiveTotal = widget.package.price + addOnTotal;

    return _BottomSheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SheetHandleAndClose(
            title: 'Add Services',
            onClose: () => Navigator.pop(context, <DoorstepAddOn>[]),
          ),
          _SoftCard(
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _DoorstepServiceImage(
                    imageUrl: widget.package.imageUrl,
                    fallbackAsset: widget.package.fallbackAsset,
                    width: 72,
                    height: 72,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.package.name,
                        style: AppTypography.quicksand(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.package.bullets.join(', '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.package.addOns.isEmpty
                ? 'No add-ons available for this package right now.'
                : 'Select add-on services for your package.',
            style: AppTypography.dmSans(
              fontSize: 14,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.package.addOns.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.package.addOns.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final addOn = widget.package.addOns[index];
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: <Widget>[
                          _SelectionCircle(selected: checked),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              addOn.title,
                              style: AppTypography.dmSans(
                                fontSize: 15,
                                color: AppColors.grey800,
                              ),
                            ),
                          ),
                          Text(
                            '₹${addOn.price}',
                            style: AppTypography.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          _SoftCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Total',
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          color: AppColors.grey600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹ $inclusiveTotal',
                        style: AppTypography.quicksand(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                        ),
                      ),
                      Text(
                        '(incl. GST)',
                        style: AppTypography.dmSans(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final selected = _selected
                        .map((index) => widget.package.addOns[index])
                        .toList();
                    Navigator.pop(context, selected);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: AppTypography.quicksand(
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
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

class _OrderDetailsSheet extends StatefulWidget {
  const _OrderDetailsSheet({
    required this.package,
    required this.addOns,
    required this.vehicle,
  });

  final DoorstepPackage package;
  final List<DoorstepAddOn> addOns;
  final VehicleItem vehicle;

  @override
  State<_OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<_OrderDetailsSheet> {
  static const int _scheduleDayCount = 30;

  late DateTime _selectedDate;
  String? _selectedTime;
  DoorstepPaymentMode _paymentMode = DoorstepPaymentMode.cod;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final inclusiveTotal = widget.package.price +
        widget.addOns.fold<int>(0, (sum, addOn) => sum + addOn.price);
    final dates = List<DateTime>.generate(
      _scheduleDayCount,
      (index) => DateTime.now().add(Duration(days: index)),
    );

    return _BottomSheetContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SheetHandleAndClose(
              title: 'Order Details',
              onClose: () => Navigator.pop(context),
            ),
            Text(
              'Select Date',
              style: AppTypography.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final selected = DateUtils.isSameDay(date, _selectedDate);
                  return InkWell(
                    onTap: () => setState(() => _selectedDate = date),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryTintStrong
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.grey200,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            index == 0 ? 'Today' : DateFormat('EEE').format(date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('dd').format(date),
                            style: AppTypography.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey800,
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.dmSans(
                              fontSize: 10,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Time Slot',
              style: AppTypography.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 10),
            _InfoBanner(
              text:
                  'Service Duration: 4:00 PM to 7:00 PM (3 hours) for doorstep scheduling.',
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth = (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List<Widget>.generate(
                    kInternalWashPreferredTimes.length,
                    (index) {
                      final slot = kInternalWashPreferredTimes[index];
                      final selected = _selectedTime == slot;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTime = slot),
                        child: Container(
                          width: slotWidth,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primaryTintStrong
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey300,
                            ),
                          ),
                          child: Text(
                            slot,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.grey800,
                              height: 1.2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <Widget>[
                _LegendDot(color: AppColors.primary, label: 'Selected'),
                _LegendDot(
                  color: AppColors.white,
                  label: 'Available',
                  outlined: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Selected Services',
              style: AppTypography.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 10),
            _SoftCard(
              child: Column(
                children: <Widget>[
                  _OrderLineItem(
                    title: widget.package.name,
                    subtitle: widget.package.categoryLabel,
                    amount: widget.package.price,
                  ),
                  ...widget.addOns.map(
                    (addOn) => Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _OrderLineItem(
                        title: addOn.title,
                        subtitle: 'Add-on',
                        amount: addOn.price,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Mode',
              style: AppTypography.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _PaymentModeButton(
                    label: 'Online',
                    selected: _paymentMode == DoorstepPaymentMode.online,
                    onTap: () =>
                        setState(() => _paymentMode = DoorstepPaymentMode.online),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaymentModeButton(
                    label: 'COD',
                    selected: _paymentMode == DoorstepPaymentMode.cod,
                    onTap: () =>
                        setState(() => _paymentMode = DoorstepPaymentMode.cod),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedTime == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        _DoorstepDraft(
                          date: _selectedDate,
                          timeSlot: _selectedTime!,
                          paymentMode: _paymentMode,
                          addOns: widget.addOns,
                        ),
                      ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.grey200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Order Preview  •  ₹$inclusiveTotal',
                  style: AppTypography.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _selectedTime == null
                        ? AppColors.grey500
                        : AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderPreviewSheet extends StatelessWidget {
  const _OrderPreviewSheet({
    required this.package,
    required this.draft,
    required this.vehicle,
    required this.address,
  });

  final DoorstepPackage package;
  final _DoorstepDraft draft;
  final VehicleItem vehicle;
  final String address;

  @override
  Widget build(BuildContext context) {
    final inclusiveTotal = package.price +
        draft.addOns.fold<int>(0, (sum, addOn) => sum + addOn.price);
    const gstPercent = CheckoutGstConfig.defaultGstPercent;
    final breakdown = CheckoutPricing.breakdownFromInclusive(
      inclusiveTotal,
      gstPercent,
    );

    return _BottomSheetContainer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SheetHandleAndClose(
              title: 'Order Preview',
              onClose: () => Navigator.pop(context),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _DoorstepServiceImage(
                    imageUrl: package.imageUrl,
                    fallbackAsset: package.fallbackAsset,
                    width: 128,
                    height: 128,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${vehicle.make} ${vehicle.model}'.trim(),
                        style: AppTypography.quicksand(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ChipPill(
                        label: package.categoryLabel,
                        backgroundColor: AppColors.primaryTint,
                        foregroundColor: AppColors.grey800,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Your Order',
              style: AppTypography.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SoftCard(
              child: Column(
                children: <Widget>[
                  _OrderLineItem(
                    title: package.name,
                    subtitle: 'Base Package',
                    amount: package.price,
                  ),
                  ...draft.addOns.map(
                    (addOn) => Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _OrderLineItem(
                        title: addOn.title,
                        subtitle: 'Add-on',
                        amount: addOn.price,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Booking Details',
              style: AppTypography.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SoftCard(
              child: Column(
                children: <Widget>[
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: DateFormat('yyyy-MM-dd').format(draft.date),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time Slot',
                    value: draft.timeSlot,
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Payment',
                    value: draft.paymentMode == DoorstepPaymentMode.cod
                        ? 'Cash on Delivery'
                        : 'Online Payment',
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Address',
                    value: address,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Bill Summary',
              style: AppTypography.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _SoftCard(
              child: Column(
                children: <Widget>[
                  _SummaryRow(
                    label: 'Subtotal (excl. GST)',
                    value: '₹${breakdown.subTotal}',
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    label: 'GST ($gstPercent%)',
                    value: '₹${breakdown.gstAmount}',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1),
                  ),
                  _SummaryRow(
                    label: 'Grand Total (incl. GST)',
                    value: '₹${breakdown.total}',
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Confirm & Book  ₹${breakdown.total}',
                  style: AppTypography.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandleAndClose extends StatelessWidget {
  const _SheetHandleAndClose({
    required this.title,
    required this.onClose,
  });

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: AppTypography.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 22),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  const _BottomSheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 42),
      decoration: const BoxDecoration(
        gradient: AppGradients.washScreenBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 64,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Text(
        text,
        style: AppTypography.dmSans(
          fontSize: 11,
          color: AppColors.grey800,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  const _ChipPill({
    required this.label,
    this.backgroundColor = AppColors.primaryTint,
    this.foregroundColor = AppColors.primary,
    this.ellipsize = true,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool ellipsize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: ellipsize ? TextOverflow.ellipsis : TextOverflow.clip,
        style: AppTypography.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.primary : AppColors.white,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.grey400,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white)
          : null,
    );
  }
}

class _OrderLineItem extends StatelessWidget {
  const _OrderLineItem({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_car_wash_rounded,
            color: AppColors.grey800,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.dmSans(
                  fontSize: 11,
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ),
        Text(
          '₹$amount',
          style: AppTypography.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.grey800),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTypography.dmSans(
                  fontSize: 13,
                  color: AppColors.grey500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: AppTypography.dmSans(
            fontSize: emphasize ? 15 : 14,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            color: emphasize ? AppColors.grey800 : AppColors.grey700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.quicksand(
            fontSize: emphasize ? 20 : 16,
            fontWeight: FontWeight.w700,
            color: emphasize ? AppColors.primary : AppColors.grey800,
          ),
        ),
      ],
    );
  }
}

class _PaymentModeButton extends StatelessWidget {
  const _PaymentModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.grey800,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.outlined = false,
  });

  final Color color;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: outlined ? AppColors.primary : color,
              width: outlined ? 2 : 0,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 12,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }
}
