import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_app_bar.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/checkout/data/local/cart_local_storage.dart';
import 'package:carrocare_flutter/features/checkout/presentation/widgets/smart_checkout_sheet.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item_filters.dart';
import 'package:carrocare_flutter/features/orders/presentation/bloc/my_orders_bloc.dart';
import 'package:carrocare_flutter/features/orders/presentation/utils/order_date_time_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RenewPage extends StatefulWidget {
  const RenewPage({super.key});

  @override
  State<RenewPage> createState() => _RenewPageState();
}

class _RenewPageState extends State<RenewPage>
    with SingleTickerProviderStateMixin {
  final CartLocalStorage _cartStorage = CartLocalStorage();
  late final TabController _tabController;
  String _token = '';
  String _customerId = '';
  int _cartCount = 0;
  Set<String> _cartVehicleIds = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    if (order.serviceType.trim().toLowerCase() != 'wash') {
      return false;
    }
    if (order.status.toLowerCase() == 'cancelled') {
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
      child: CarroCareScaffold(
        title: 'Renew Order',
        onBack: _onBack,
        actions: <Widget>[
          CarroCareCartAction(
            count: _cartCount,
            onTap: () async {
              await context.push('/cart');
              await _refreshCartState();
            },
          ),
        ],
        body: BlocBuilder<MyOrdersBloc, MyOrdersState>(
          builder: (context, state) {
            if (state is MyOrdersLoading || state is MyOrdersInitial) {
              return const CarroCareLoadingOverlay();
            }
            if (state is MyOrdersFailure) {
              return Center(
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                ),
              );
            }

            final allOrders = (state as MyOrdersLoaded).orders;
            final subs = subscriptionOrders(allOrders);
            final oneTime = oneTimeOrders(allOrders);

            if (allOrders.isEmpty) {
              return Center(
                child: Image.asset(
                  'assets/images/placeholders.png',
                  fit: BoxFit.contain,
                ),
              );
            }

            return Column(
              children: <Widget>[
                Material(
                  color: AppColors.primary,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.white,
                    indicatorWeight: 3,
                    labelColor: AppColors.white,
                    unselectedLabelColor:
                        AppColors.white.withValues(alpha: 0.65),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: <Widget>[
                      Tab(text: 'Subscriptions (${subs.length})'),
                      Tab(text: 'One-time (${oneTime.length})'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _RenewTabBody(
                        orders: subs,
                        emptyTitle: 'No subscriptions to renew',
                        emptySubtitle:
                            'Monthly autopay plans appear here.',
                        cartVehicleIds: _cartVehicleIds,
                        showSmartCheckout: _showSmartCheckout,
                        validLabel: _validLabel,
                        onSmartCheckout: _onSmartCheckout,
                      ),
                      _RenewTabBody(
                        orders: oneTime,
                        emptyTitle: 'No one-time orders to renew',
                        emptySubtitle:
                            'Prepaid and single purchases appear here.',
                        cartVehicleIds: _cartVehicleIds,
                        showSmartCheckout: _showSmartCheckout,
                        validLabel: _validLabel,
                        onSmartCheckout: _onSmartCheckout,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        footer: Container(
          width: double.infinity,
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
      ),
    );
  }
}

class _RenewTabBody extends StatelessWidget {
  const _RenewTabBody({
    required this.orders,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.cartVehicleIds,
    required this.showSmartCheckout,
    required this.validLabel,
    required this.onSmartCheckout,
  });

  final List<OrderItem> orders;
  final String emptyTitle;
  final String emptySubtitle;
  final Set<String> cartVehicleIds;
  final bool Function(OrderItem order) showSmartCheckout;
  final String Function(OrderItem order) validLabel;
  final Future<void> Function(OrderItem order, bool checked) onSmartCheckout;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: <Widget>[
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _RenewCard(
          order: order,
          inCart: cartVehicleIds.contains(order.vehicleId),
          showSmartCheckout: showSmartCheckout(order),
          validLabel: validLabel(order),
          onSmartCheckout: (checked) => onSmartCheckout(order, checked),
        );
      },
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
                  child: _col(
                    'Status :',
                    order.status,
                    labelStyle,
                    valueStyle.copyWith(color: AppColors.primary),
                  ),
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
                    OrderDateTimeDisplay.formatDateTime(order.dateAndTime),
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
