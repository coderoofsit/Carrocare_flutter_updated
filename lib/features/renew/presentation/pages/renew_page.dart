import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/smart_checkout_sheet.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/presentation/bloc/my_orders_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RenewPage extends StatefulWidget {
  const RenewPage({super.key});

  @override
  State<RenewPage> createState() => _RenewPageState();
}

class _RenewPageState extends State<RenewPage> {
  final CartLocalStorage _cartStorage = CartLocalStorage();
  String _token = '';
  String _customerId = '';
  int _cartCount = 0;
  Set<String> _cartVehicleIds = <String>{};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token') ?? '';
    _customerId = prefs.getString('customer_id') ?? '';
    await _refreshCartState();
    if (!mounted) return;
    if (_token.isEmpty || _customerId.isEmpty) {
      context.go('/login');
      return;
    }
    context.read<MyOrdersBloc>().add(
          MyOrdersRequested(token: _token, customerId: _customerId),
        );
  }

  Future<void> _refreshCartState() async {
    _cartCount = await _cartStorage.count();
    _cartVehicleIds = await _cartStorage.vehicleIds();
    if (mounted) setState(() {});
  }

  void _onBack() {
    context.go('/my-orders');
  }

  Future<void> _onSmartCheckout(OrderItem order, bool checked) async {
    if (!checked) {
      await _cartStorage.removeByVehicleId(order.vehicleId);
      await _refreshCartState();
      return;
    }
    final added = await showRenewSmartCheckoutSheet(
      context: context,
      order: order,
      customerId: _customerId,
      token: _token,
    );
    if (!mounted || !added) return;
    await _refreshCartState();
  }

  String _validLabel(OrderItem order) {
    if (order.paymentType.toLowerCase() == 'monthly') {
      return order.nextDue;
    }
    return order.valid;
  }

  bool _showSmartCheckout(OrderItem order) {
    if (order.paymentType.toLowerCase() == 'monthly') {
      return false;
    }
    if (order.serviceType.toLowerCase() == 'wash' &&
        order.status.toLowerCase() == 'cancelled') {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              SizedBox(
                height: kToolbarHeight,
                child: Row(
                  children: <Widget>[
                    GestureDetector(
                      onTap: _onBack,
                      child: Container(
                        width: 35,
                        height: 35,
                        margin: const EdgeInsets.all(10),
                        padding: const EdgeInsets.all(5),
                        child: Image.asset('assets/images/back.png'),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'RENEW ORDER',
                        style: TextStyle(
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
                  child: BlocBuilder<MyOrdersBloc, MyOrdersState>(
                    builder: (context, state) {
                      if (state is MyOrdersLoading ||
                          state is MyOrdersInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      if (state is MyOrdersFailure) {
                        return Center(
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final orders = (state as MyOrdersLoaded).orders;
                      if (orders.isEmpty) {
                        return Center(
                          child: Image.asset(
                            'assets/images/placeholders.png',
                            fit: BoxFit.contain,
                          ),
                        );
                      }

                      return Column(
                        children: <Widget>[
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                return _RenewCard(
                                  order: order,
                                  inCart: _cartVehicleIds.contains(
                                    order.vehicleId,
                                  ),
                                  showSmartCheckout: _showSmartCheckout(order),
                                  validLabel: _validLabel(order),
                                  onSmartCheckout: (checked) =>
                                      _onSmartCheckout(order, checked),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFEDEFF1),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () => context.push('/cart'),
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
                                  'Make Payment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
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
      ),
    );
  }
}

class _RenewCard extends StatelessWidget {
  const _RenewCard({
    required this.order,
    required this.inCart,
    required this.showSmartCheckout,
    required this.validLabel,
    required this.onSmartCheckout,
  });

  final OrderItem order;
  final bool inCart;
  final bool showSmartCheckout;
  final String validLabel;
  final ValueChanged<bool> onSmartCheckout;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Color(0xFF666666),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
    const valueStyle = TextStyle(
      color: AppColors.black,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showSmartCheckout)
              Row(
                children: <Widget>[
                  Checkbox(
                    value: inCart,
                    activeColor: AppColors.primary,
                    onChanged: (value) => onSmartCheckout(value ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Add to smart checkout',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            if (showSmartCheckout) const Divider(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _col('Status :', order.status, labelStyle,
                      valueStyle.copyWith(color: AppColors.primary)),
                ),
                Expanded(
                  child: _col('Valid :', validLabel, labelStyle, valueStyle),
                ),
              ],
            ),
            const Divider(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _col(
                    'Vehicle Model :',
                    '${order.vehicleMake}-${order.vehicleModel}',
                    labelStyle,
                    valueStyle,
                  ),
                ),
                Expanded(
                  child: _col(
                    'Package Type :',
                    order.packageType,
                    labelStyle,
                    valueStyle,
                  ),
                ),
              ],
            ),
            const Divider(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _col(
                    'Vehicle No. :',
                    order.vehicleNo,
                    labelStyle,
                    valueStyle,
                  ),
                ),
                Expanded(
                  child: _col(
                    'Serive Type :',
                    order.serviceType,
                    labelStyle,
                    valueStyle,
                  ),
                ),
              ],
            ),
            const Divider(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _col(
                    'Date :',
                    order.dateAndTime,
                    labelStyle,
                    valueStyle,
                  ),
                ),
                Expanded(
                  child: _col(
                    'Amount :',
                    '₹ ${order.totalAmount}',
                    labelStyle,
                    valueStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _col(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: labelStyle),
        Text(value, style: valueStyle),
      ],
    );
  }
}
