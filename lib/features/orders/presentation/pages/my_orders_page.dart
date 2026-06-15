import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item_filters.dart';
import 'package:carrocare_flutter/features/orders/presentation/bloc/my_orders_bloc.dart';
import 'package:carrocare_flutter/features/orders/presentation/pages/order_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<MyOrdersBloc>().add(const MyOrdersStarted());
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final customerId = prefs.getString('customer_id') ?? '';
    if (!mounted) return;
    if (token.isEmpty || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session missing. Please login again.')),
      );
      context.go('/login');
      return;
    }
    context.read<MyOrdersBloc>().add(
          MyOrdersRequested(token: token, customerId: customerId),
        );
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  void _openOrderDetail(List<OrderItem> list, int index) {
    context.push(
      '/order-detail',
      extra: OrderDetailArgs(
        order: list[index],
        orders: list,
        index: index,
      ),
    );
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
                        'MY ORDERS',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 45),
                  ],
                ),
              ),
              BlocBuilder<MyOrdersBloc, MyOrdersState>(
                builder: (context, state) {
                  if (state is! MyOrdersLoaded) {
                    return const SizedBox.shrink();
                  }
                  final subs = subscriptionOrders(state.orders);
                  final oneTime = oneTimeOrders(state.orders);
                  return Material(
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
                  );
                },
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFEDEFF1),
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _loadOrders,
                    child: BlocConsumer<MyOrdersBloc, MyOrdersState>(
                      listener: (context, state) {
                        if (state is MyOrdersFailure &&
                            state.message.contains('Session expired')) {
                          context.go('/login');
                        }
                      },
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
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.25,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadOrders,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        final allOrders = (state as MyOrdersLoaded).orders;
                        if (allOrders.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: <Widget>[
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.2,
                              ),
                              Center(
                                child: Image.asset(
                                  'assets/images/placeholders.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'No orders yet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        final subs = subscriptionOrders(allOrders);
                        final oneTime = oneTimeOrders(allOrders);

                        return TabBarView(
                          controller: _tabController,
                          children: <Widget>[
                            _OrdersTabBody(
                              orders: subs,
                              variant: _OrderCardVariant.subscription,
                              emptyTitle: 'No active subscriptions',
                              emptySubtitle:
                                  'Monthly autopay plans appear here.',
                              showRenew: true,
                              onOpenDetail: _openOrderDetail,
                            ),
                            _OrdersTabBody(
                              orders: oneTime,
                              variant: _OrderCardVariant.oneTime,
                              emptyTitle: 'No one-time orders',
                              emptySubtitle:
                                  'Prepaid and single purchases appear here.',
                              showRenew: false,
                              onOpenDetail: _openOrderDetail,
                            ),
                          ],
                        );
                      },
                    ),
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

class _OrdersTabBody extends StatelessWidget {
  const _OrdersTabBody({
    required this.orders,
    required this.variant,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.showRenew,
    required this.onOpenDetail,
  });

  final List<OrderItem> orders;
  final _OrderCardVariant variant;
  final String emptyTitle;
  final String emptySubtitle;
  final bool showRenew;
  final void Function(List<OrderItem> list, int index) onOpenDetail;

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
                  variant == _OrderCardVariant.subscription
                      ? Icons.autorenew
                      : Icons.receipt_long_outlined,
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

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _OrderCard(
                order: orders[index],
                variant: variant,
                onTap: () => onOpenDetail(orders, index),
              );
            },
          ),
        ),
        if (showRenew)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/renew'),
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
                  'Renew',
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
  }
}

enum _OrderCardVariant { subscription, oneTime }

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.variant,
    required this.onTap,
  });

  final OrderItem order;
  final _OrderCardVariant variant;
  final VoidCallback onTap;

  bool get _showReason {
    final service = order.serviceType.toLowerCase();
    return (service.contains('door step wash') ||
            service.contains('door step detailing') ||
            service.contains('door step addon')) &&
        order.status == 'Cancel Requested';
  }

  String get _highlightLabel =>
      variant == _OrderCardVariant.subscription ? 'Next due : ' : 'Valid until : ';

  String get _highlightValue {
    if (variant == _OrderCardVariant.subscription) {
      final due = order.nextDue.trim();
      return due.isEmpty ? '—' : due;
    }
    final valid = order.valid.trim();
    return valid.isEmpty ? '—' : valid;
  }

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Color(0xFF313030),
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );
    const valueStyle = TextStyle(
      color: AppColors.black,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );

    final chipLabel = variant == _OrderCardVariant.subscription
        ? 'Monthly · Autopay'
        : 'One-time';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      chipLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.status.toUpperCase(),
                    style: valueStyle.copyWith(
                      fontSize: 14,
                      color: order.status == 'Cancel Requested'
                          ? AppColors.primary
                          : AppColors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _orderIdRow(order.orderId, labelStyle, valueStyle),
              _row(_highlightLabel, _highlightValue, labelStyle, valueStyle),
              _row(
                'Payment method : ',
                _displayValue(order.paymentMode),
                labelStyle,
                valueStyle,
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Date : ', style: labelStyle),
                        Text(order.dateAndTime, style: valueStyle),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        const Text('Service type : ', style: labelStyle),
                        Text(
                          order.serviceType,
                          textAlign: TextAlign.right,
                          style: valueStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Plate Number : ', style: labelStyle),
                        Text(order.vehicleNo, style: valueStyle),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        const Text('Plan : ', style: labelStyle),
                        Text(
                          order.plan,
                          textAlign: TextAlign.right,
                          style: valueStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showReason) ...<Widget>[
                const SizedBox(height: 8),
                const Text('Reason for Cancel : ', style: labelStyle),
                Text(order.reason, style: valueStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _displayValue(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  Widget _orderIdRow(
    String orderId,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text('Order Id : ', style: labelStyle),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                orderId,
                maxLines: 1,
                style: valueStyle.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    TextStyle labelStyle,
    TextStyle valueStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: labelStyle),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
