import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/widgets/animated_gradient_badge.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item_filters.dart';
import 'package:carrocare_flutter/features/orders/presentation/bloc/my_orders_bloc.dart';
import 'package:carrocare_flutter/features/orders/presentation/pages/order_detail_page.dart';
import 'package:carrocare_flutter/features/orders/presentation/utils/order_date_time_display.dart';
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
  SubscriptionStatusFilter _subscriptionFilter =
      SubscriptionStatusFilter.all;
  OneTimeStatusFilter _oneTimeFilter = OneTimeStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      child: CarroCareScaffold(
        title: 'My Orders',
        onBack: _onBack,
        body: Column(
          children: <Widget>[
            BlocBuilder<MyOrdersBloc, MyOrdersState>(
              builder: (context, state) {
                if (state is! MyOrdersLoaded) {
                  return const SizedBox.shrink();
                }
                final subs = subscriptionOrders(state.orders);
                final oneTime = oneTimeOrders(state.orders);
                return Column(
                  mainAxisSize: MainAxisSize.min,
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
                    _StatusFilterChips(
                      tabIndex: _tabController.index,
                      subscriptionFilter: _subscriptionFilter,
                      oneTimeFilter: _oneTimeFilter,
                      onSubscriptionSelected: (filter) {
                        setState(() => _subscriptionFilter = filter);
                      },
                      onOneTimeSelected: (filter) {
                        setState(() => _oneTimeFilter = filter);
                      },
                    ),
                  ],
                );
              },
            ),
            Expanded(
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
                      return const Center(child: CarroCareLoadingOverlay());
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
                        final filteredSubs = filterSubscriptionOrders(
                          subs,
                          _subscriptionFilter,
                        );
                        final filteredOneTime = filterOneTimeOrders(
                          oneTime,
                          _oneTimeFilter,
                        );
                        final subsFiltered =
                            _subscriptionFilter !=
                            SubscriptionStatusFilter.all;
                        final oneTimeFiltered =
                            _oneTimeFilter != OneTimeStatusFilter.all;
                        final subsEmpty = emptyMessageForSubscriptionFilter(
                          _subscriptionFilter,
                        );
                        final oneTimeEmpty = emptyMessageForOneTimeFilter(
                          _oneTimeFilter,
                        );

                        return TabBarView(
                          controller: _tabController,
                          children: <Widget>[
                            _OrdersTabBody(
                              orders: filteredSubs,
                              variant: _OrderCardVariant.subscription,
                              emptyTitle: subsFiltered &&
                                      subsEmpty.isNotEmpty
                                  ? subsEmpty
                                  : 'No active subscriptions',
                              emptySubtitle: subsFiltered
                                  ? 'Try another status filter.'
                                  : 'Monthly autopay plans appear here.',
                              showRenew: true,
                              onOpenDetail: _openOrderDetail,
                            ),
                            _OrdersTabBody(
                              orders: filteredOneTime,
                              variant: _OrderCardVariant.oneTime,
                              emptyTitle: oneTimeFiltered &&
                                      oneTimeEmpty.isNotEmpty
                                  ? oneTimeEmpty
                                  : 'No one-time orders',
                              emptySubtitle: oneTimeFiltered
                                  ? 'Try another status filter.'
                                  : 'Prepaid and single purchases appear here.',
                              showRenew: false,
                              onOpenDetail: _openOrderDetail,
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

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({
    required this.tabIndex,
    required this.subscriptionFilter,
    required this.oneTimeFilter,
    required this.onSubscriptionSelected,
    required this.onOneTimeSelected,
  });

  final int tabIndex;
  final SubscriptionStatusFilter subscriptionFilter;
  final OneTimeStatusFilter oneTimeFilter;
  final ValueChanged<SubscriptionStatusFilter> onSubscriptionSelected;
  final ValueChanged<OneTimeStatusFilter> onOneTimeSelected;

  static const List<(SubscriptionStatusFilter, String)> _subscriptionOptions =
      <(SubscriptionStatusFilter, String)>[
    (SubscriptionStatusFilter.all, 'All'),
    (SubscriptionStatusFilter.active, 'Active'),
    (SubscriptionStatusFilter.overDue, 'Over Due'),
    (SubscriptionStatusFilter.paused, 'Paused'),
    (SubscriptionStatusFilter.completed, 'Completed'),
    (SubscriptionStatusFilter.cancelled, 'Cancelled'),
  ];

  static const List<(OneTimeStatusFilter, String)> _oneTimeOptions =
      <(OneTimeStatusFilter, String)>[
    (OneTimeStatusFilter.all, 'All'),
    (OneTimeStatusFilter.paid, 'Paid'),
    (OneTimeStatusFilter.notCompleted, 'Not Completed'),
    (OneTimeStatusFilter.completed, 'Completed'),
    (OneTimeStatusFilter.cancelRequested, 'Cancel Requested'),
    (OneTimeStatusFilter.cancelled, 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final isSubscriptionTab = tabIndex == 0;
    return Material(
      color: AppColors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: isSubscriptionTab
              ? <Widget>[
                  for (var i = 0; i < _subscriptionOptions.length; i++) ...<
                      Widget>[
                    if (i > 0) const SizedBox(width: 8),
                    _buildChip(
                      label: _subscriptionOptions[i].$2,
                      selected:
                          subscriptionFilter == _subscriptionOptions[i].$1,
                      onSelected: () =>
                          onSubscriptionSelected(_subscriptionOptions[i].$1),
                    ),
                  ],
                ]
              : <Widget>[
                  for (var i = 0; i < _oneTimeOptions.length; i++) ...<
                      Widget>[
                    if (i > 0) const SizedBox(width: 8),
                    _buildChip(
                      label: _oneTimeOptions[i].$2,
                      selected: oneTimeFilter == _oneTimeOptions[i].$1,
                      onSelected: () =>
                          onOneTimeSelected(_oneTimeOptions[i].$1),
                    ),
                  ],
                ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.grey100,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.grey300,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.white : AppColors.grey800,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
      color: AppColors.grey600,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    const valueStyle = TextStyle(
      color: AppColors.grey800,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    );
    const orderIdValueStyle = TextStyle(
      color: AppColors.grey800,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.3,
    );

    final chipLabel = variant == _OrderCardVariant.subscription
        ? 'Monthly · Autopay'
        : 'One-time';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  AnimatedGradientBadge(
                    label: chipLabel,
                    vibrant: variant == _OrderCardVariant.subscription,
                  ),
                  const Spacer(),
                  Text(
                    order.displayStatus.toUpperCase(),
                    style: valueStyle.copyWith(
                      fontSize: 13,
                      letterSpacing: 0.4,
                      color: order.displayStatus == 'Cancel Requested'
                          ? AppColors.primary
                          : AppColors.grey800,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.grey200),
              ),
              _infoBlock(
                label: 'Order Id',
                value: order.orderId,
                labelStyle: labelStyle,
                valueStyle: orderIdValueStyle,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _infoBlock(
                      label: variant == _OrderCardVariant.subscription
                          ? 'Next due'
                          : 'Valid until',
                      value: _highlightValue,
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoBlock(
                      label: 'Payment method',
                      value: _displayValue(order.paymentMode),
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _infoBlock(
                      label: 'Date',
                      value: OrderDateTimeDisplay.formatDate(order.dateAndTime),
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoBlock(
                      label: 'Time',
                      value: OrderDateTimeDisplay.formatTime(order.dateAndTime),
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _infoBlock(
                      label: 'Service type',
                      value: _displayValue(order.serviceType),
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoBlock(
                      label: 'Package type',
                      value: _displayValue(order.packageType),
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _infoBlock(
                      label: 'Plate Number',
                      value: _displayValue(order.vehicleNo),
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoBlock(
                      label: 'Plan',
                      value: _displayValue(order.plan),
                      labelStyle: labelStyle,
                      valueStyle: valueStyle,
                    ),
                  ),
                ],
              ),
              if (_showReason) ...<Widget>[
                const SizedBox(height: 12),
                _infoBlock(
                  label: 'Reason for Cancel',
                  value: order.reason,
                  labelStyle: labelStyle,
                  valueStyle: valueStyle,
                ),
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

  static Widget _infoBlock({
    required String label,
    required String value,
    required TextStyle labelStyle,
    required TextStyle valueStyle,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
