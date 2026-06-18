import 'package:carrocare_flutter/core/utils/service_description_display.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_gradients.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_app_bar.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/core/checkout_vehicle_gate.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/checkout/domain/entities/payment_option_args.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/smart_checkout_sheet.dart';
import 'package:carrocare_flutter/features/vehicle_list/domain/entities/vehicle_list_args.dart';
import 'package:carrocare_flutter/features/vehicle_list/presentation/bloc/vehicle_list_bloc.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/add_vehicle_args.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key, required this.args});

  final VehicleListArgs args;

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  final CartLocalStorage _cartStorage = CartLocalStorage();
  String _token = '';
  String _customerId = '';
  int _cartCount = 0;
  /// Vehicle ids in cart for [widget.args.header] only (not other services).
  Set<String> _cartVehicleIdsForService = <String>{};

  @override
  void initState() {
    super.initState();
    _loadAndFetch();
  }

  Future<void> _loadAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _customerId = prefs.getString('customer_id') ?? '';
    await _refreshCartState();
    if (!mounted) return;
    context.read<VehicleListBloc>().add(
          VehicleListRequested(
            args: widget.args,
            customerId: _customerId,
            token: _token,
          ),
        );
  }

  Future<void> _refresh() async {
    if (_customerId.isEmpty) {
      await _loadAndFetch();
      return;
    }
    if (!mounted) return;
    context.read<VehicleListBloc>().add(
          VehicleListRequested(
            args: widget.args,
            customerId: _customerId,
            token: _token,
          ),
        );
  }

  Future<void> _openAddVehicle() async {
    final added = await context.push<bool>(
      '/add-vehicle',
      extra: AddVehicleArgs(
        preselectedCategory: normalizeVehicleCategory(widget.args.carName),
      ),
    );
    if (added == true) {
      await _refresh();
    }
  }

  Future<void> _refreshCartState() async {
    _cartCount = await _cartStorage.count();
    final items = await _cartStorage.getItems();
    final serviceHeader = widget.args.header;
    _cartVehicleIdsForService = items
        .where(
          (item) =>
              item.serviceType == serviceHeader || item.header == serviceHeader,
        )
        .map((item) => item.carId)
        .toSet();
    if (mounted) setState(() {});
  }

  Future<void> _onSubscribe(VehicleItem vehicle) async {
    if (_token.isEmpty || _customerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again.')),
      );
      return;
    }

    final message = await CheckoutVehicleGate.blockMessageIfActiveSubscription(
      customerId: _customerId,
      vehicleId: vehicle.id,
      serviceHeader: widget.args.header,
    );
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    await context.push(
      '/payment-option',
      extra: PaymentOptionArgs(
        booking: widget.args,
        vehicle: vehicle,
      ),
    );
  }

  Future<void> _onSmartCheckout(VehicleItem vehicle, bool checked) async {
    if (!checked) {
      await _cartStorage.removeByVehicleId(vehicle.id);
      await _refreshCartState();
      return;
    }

    if (_token.isEmpty || _customerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again.')),
      );
      return;
    }

    final added = await showSmartCheckoutSheet(
      context: context,
      booking: widget.args,
      vehicle: vehicle,
      customerId: _customerId,
      token: _token,
    );
    if (!mounted) return;
    if (!added) {
      // User closed sheet without adding — keep checkbox unchecked.
      await _refreshCartState();
      return;
    }

    await _refreshCartState();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart. Open cart when you are ready to pay.'),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: widget.args.header,
      onBack: () => context.pop(),
      backgroundDecoration: const BoxDecoration(
        gradient: AppGradients.washScreenBackground,
      ),
      actions: <Widget>[
        CarroCareCartAction(
          count: _cartCount,
          onTap: () async {
            await context.push('/cart');
            await _refreshCartState();
          },
        ),
      ],
      body: BlocConsumer<VehicleListBloc, VehicleListState>(
        listener: (context, state) {
          if (state is VehicleListFailure &&
              state.message.contains('Session expired')) {
            context.go('/login');
          }
        },
        builder: (context, state) {
          if (state is VehicleListLoading || state is VehicleListInitial) {
            return const CarroCareLoadingOverlay();
          }
          if (state is VehicleListFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
              ),
            );
          }

          final loaded = state as VehicleListLoaded;
          return Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    loaded.hideBottomBar ? 16 : 100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _SectionHeading(
                        title: '${loaded.args.header} details',
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppDecorations.cardRadius),
                          border: Border.all(color: AppColors.grey200),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ServiceDescriptionDisplay.buildPointList(
                          loaded.args.carDesc,
                          style: AppTypography.dmSans(
                            fontSize: 14,
                            color: AppColors.grey700,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SectionHeading(title: 'Subscription price'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          borderRadius:
                              BorderRadius.circular(AppDecorations.cardRadius),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Text(
                              '₹ ${loaded.args.displayPrice}',
                              style: AppTypography.quicksand(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'per month',
                              style: AppTypography.dmSans(
                                fontSize: 13,
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _SectionHeading(title: 'Select vehicle'),
                      Text(
                        'Choose a vehicle to subscribe or add it to smart checkout.',
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          color: AppColors.grey600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (loaded.vehicles.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(
                              AppDecorations.cardRadius,
                            ),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Column(
                            children: <Widget>[
                              Image.asset(
                                'assets/images/tyre.png',
                                height: 160,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No vehicles added yet',
                                style: AppTypography.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add a vehicle to continue with your subscription.',
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...loaded.vehicles.map(
                          (vehicle) => _BookingVehicleCard(
                            item: vehicle,
                            inCart: _cartVehicleIdsForService
                                .contains(vehicle.id),
                            onSubscribe: () => _onSubscribe(vehicle),
                            onSmartCheckout: (checked) =>
                                _onSmartCheckout(vehicle, checked),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (!loaded.hideBottomBar)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: ElevatedButton(
                      onPressed: _openAddVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size.fromHeight(50),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDecorations.buttonRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        'Add vehicle',
                        style: AppTypography.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: AppTypography.quicksand(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.grey800,
        ),
      ),
    );
  }
}

class _BookingVehicleCard extends StatelessWidget {
  const _BookingVehicleCard({
    required this.item,
    required this.inCart,
    required this.onSubscribe,
    required this.onSmartCheckout,
  });

  final VehicleItem item;
  final bool inCart;
  final VoidCallback onSubscribe;
  final ValueChanged<bool> onSmartCheckout;

  @override
  Widget build(BuildContext context) {
    final title = '${item.make}-${item.model}'.trim();
    final displayTitle = title == '-' || title.isEmpty ? 'Vehicle' : title;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: _VehicleChip(
                  label: _displayValue(item.vehicleNo),
                  icon: Icons.confirmation_number_outlined,
                ),
              ),
              if (item.color.trim().isNotEmpty)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _VehicleChip(
                    label: _displayValue(item.color),
                    icon: Icons.palette_outlined,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayTitle,
                  style: AppTypography.quicksand(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _InfoBlock(
                        label: 'Parking lot',
                        value: _displayValue(item.parkingLotNo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoBlock(
                        label: 'Parking area',
                        value: _displayValue(item.parkingArea),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _InfoBlock(
                        label: 'Preferred schedule',
                        value: _displayValue(item.preferredSchedule),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoBlock(
                        label: 'Preferred time',
                        value: _displayValue(item.preferredTime),
                      ),
                    ),
                  ],
                ),
                if (item.apartmentName.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.apartmentName.trim(),
                            style: AppTypography.dmSans(
                              fontSize: 12,
                              color: AppColors.grey700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: inCart,
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        onChanged: (value) =>
                            onSmartCheckout(value ?? false),
                      ),
                      Expanded(
                        child: Text(
                          inCart
                              ? 'Added to smart checkout'
                              : 'Add to smart checkout',
                          style: AppTypography.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(44),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDecorations.buttonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      'Subscribe',
                      style: AppTypography.quicksand(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
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

  static String _displayValue(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 12,
            color: AppColors.grey500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
          ),
        ),
      ],
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}
