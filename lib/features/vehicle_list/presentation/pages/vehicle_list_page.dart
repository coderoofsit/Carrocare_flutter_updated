import 'package:carrocare_flutter/core/theme/app_colors.dart';
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
import 'package:flutter_svg/flutter_svg.dart';
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
    final headerTitle = widget.args.carName.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 35,
                      height: 35,
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset('assets/images/back.png'),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      headerTitle,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await context.push('/cart');
                      await _refreshCartState();
                    },
                    child: SizedBox(
                      width: 35,
                      height: 35,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          Center(
                            child: SvgPicture.asset(
                              'assets/vectors/ic_cart.svg',
                              width: 25,
                              height: 25,
                            ),
                          ),
                          if (_cartCount > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.white),
                                ),
                                child: Text(
                                  '$_cartCount',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFEDEFF1),
                child: BlocConsumer<VehicleListBloc, VehicleListState>(
                  listener: (context, state) {
                    if (state is VehicleListFailure &&
                        state.message.contains('Session expired')) {
                      context.go('/login');
                    }
                  },
                  builder: (context, state) {
                    if (state is VehicleListLoading ||
                        state is VehicleListInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
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
                            padding: const EdgeInsets.only(
                              left: 7,
                              right: 7,
                              bottom: 90,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _SectionHeading(
                                  title: '${loaded.args.header} Details',
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    _stripHtml(loaded.args.carDesc),
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                                const _SectionHeading(
                                  title: 'Subscription Price',
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    '₹ ${loaded.args.displayPrice}',
                                    style: const TextStyle(
                                      color: AppColors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const _SectionHeading(title: 'Select Vehicle'),
                                if (loaded.vehicles.isEmpty)
                                  Column(
                                    children: <Widget>[
                                      Image.asset(
                                        'assets/images/tyre.png',
                                        height: 200,
                                      ),
                                      const Text(
                                        'No vehicles added yet',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  ...loaded.vehicles.map(
                                    (vehicle) => _BookingVehicleCard(
                                      item: vehicle,
                                      inCart: _cartVehicleIdsForService
                                          .contains(vehicle.id),
                                      onSubscribe: () =>
                                          _onSubscribe(vehicle),
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
                            height: 90,
                            width: double.infinity,
                            color: const Color(0xFFEDEFF1),
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: _openAddVehicle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              child: const Text(
                                'Add vehicle',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 5, top: 10, bottom: 5),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: 100,
          height: 2,
          margin: const EdgeInsets.only(left: 5, bottom: 5),
          color: AppColors.primary,
        ),
      ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 140,
              height: 120,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Image.network(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/placeholder.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${item.make}-${item.model}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const Divider(height: 10, color: Color(0xFFE0E0E0)),
                  _kv('Vehicle No.', item.vehicleNo),
                  _kv('Parking Lot', item.parkingLotNo),
                  _kv('Vehicle Color', item.color),
                  _kv('Parking Area', item.parkingArea),
                  _kv('Pref. Schedule', item.preferredSchedule),
                  _kv('Pref. Time', item.preferredTime),
                  _kv('Apartment Name', item.apartmentName),
                  const Divider(height: 10, color: Color(0xFFE0E0E0)),
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: inCart,
                        activeColor: AppColors.primary,
                        onChanged: (value) =>
                            onSmartCheckout(value ?? false),
                      ),
                      Expanded(
                        child: Text(
                          inCart
                              ? 'In cart (tap to remove)'
                              : 'Add to smart checkout',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: const Text(
                        'Subscribe',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Text(
              '$key :',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.black,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
