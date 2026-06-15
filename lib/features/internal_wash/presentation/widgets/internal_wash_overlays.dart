import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/pages/internal_wash_page.dart';
import 'package:carrocare_flutter/features/internal_wash/presentation/widgets/internal_wash_field.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bottom-nav "Internal Car Wash" popup + order list (Android `popupinternal` / `orderrl`).
class InternalWashEntryOverlay extends StatefulWidget {
  const InternalWashEntryOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<InternalWashEntryOverlay> createState() =>
      _InternalWashEntryOverlayState();
}

class _InternalWashEntryOverlayState extends State<InternalWashEntryOverlay> {
  bool _showOrderList = false;
  bool _loadingOrders = false;
  List<OrderItem> _orders = <OrderItem>[];
  String? _selectedOrderId;
  OrderItem? _previewOrder;

  final OrdersRepository _repository = sl<OrdersRepository>();

  Future<void> _openOrderList() async {
    setState(() {
      _loadingOrders = true;
      _showOrderList = true;
    });
    final prefs = await SharedPreferences.getInstance();
    try {
      final orders = await _repository.getInternalOrders(
        token: prefs.getString('token') ?? '',
        customerId: prefs.getString('customer_id') ?? '',
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loadingOrders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingOrders = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _selectOrder(OrderItem order) {
    widget.onClose();
    context.push(
      '/internal-wash',
      extra: InternalWashArgs(
        orderId: order.orderId,
        vehicleId: order.vehicleId,
        vehicleMake: order.vehicleMake,
        vehicleModel: order.vehicleModel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: widget.onClose,
          child: const ColoredBox(
            color: Color(0x88000000),
            child: SizedBox.expand(),
          ),
        ),
        if (_showOrderList)
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Card(
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                  ),
                  child: _loadingOrders
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        )
                      : _orders.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Text(
                                    '* Note : Internal wash only eligible for Car Wash Bookings',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: widget.onClose,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.white,
                                      ),
                                      child: const Text('back'),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(12),
                              itemCount: _orders.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final order = _orders[index];
                                return _InternalOrderRow(
                                  order: order,
                                  groupValue: _selectedOrderId,
                                  onSelect: () => _selectOrder(order),
                                  onViewDetails: () {
                                    setState(() => _previewOrder = order);
                                  },
                                );
                              },
                            ),
                ),
              ),
            ),
          )
        else
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Expanded(
                            child: Text(
                              'INTERNAL CLEAN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: SvgPicture.asset(
                              'assets/vectors/ic_cancel.svg',
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InternalWashArrowField(
                        value: _selectedOrderId ?? '',
                        hint: 'Order Id',
                        onTap: _openOrderList,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_selectedOrderId == null ||
                                  _selectedOrderId!.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please Select your Order Id',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'submit',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_previewOrder != null)
          _InternalOrderPreviewCard(
            order: _previewOrder!,
            onClose: () => setState(() => _previewOrder = null),
          ),
      ],
    );
  }
}

class _InternalOrderRow extends StatelessWidget {
  const _InternalOrderRow({
    required this.order,
    required this.groupValue,
    required this.onSelect,
    required this.onViewDetails,
  });

  final OrderItem order;
  final String? groupValue;
  final VoidCallback onSelect;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: RadioListTile<String>(
            value: order.orderId,
            groupValue: groupValue,
            onChanged: (_) => onSelect(),
            title: Text(
              order.orderId,
              style: const TextStyle(fontSize: 16),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        TextButton(
          onPressed: onViewDetails,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 30),
          ),
          child: const Text('View Details'),
        ),
      ],
    );
  }
}

class _InternalOrderPreviewCard extends StatelessWidget {
  const _InternalOrderPreviewCard({
    required this.order,
    required this.onClose,
  });

  final OrderItem order;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final validText = order.washDetails == '1' ? order.nextDue : order.valid;
    final showDiscount =
        order.discountAmount.isNotEmpty && order.discountAmount != '0';

    return GestureDetector(
      onTap: onClose,
      child: ColoredBox(
        color: const Color(0x88000000),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _previewRow('Date : ', order.dateAndTime),
                    _previewRow('Payment ID : ', order.orderId),
                    _previewRow('Service Type : ', order.serviceType),
                    _previewRow('Payment Type : ', order.paymentType),
                    _previewRow('Package Type : ', order.packageType),
                    _previewRow('Vehicle Make : ', order.vehicleMake),
                    _previewRow('Vehicle Model : ', order.vehicleModel),
                    _previewRow('Vehicle No : ', order.vehicleNo),
                    _previewRow('Package Value : ', '₹ ${order.packageValue}'),
                    if (showDiscount)
                      _previewRow('Discount : ', order.discountAmount),
                    _previewRow('Total Amount : ', '₹ ${order.totalAmount}'),
                    _previewRow('Payment Mode : ', order.paymentMode),
                    _previewRow('Paid Count : ', order.paidCount),
                    _previewRow('Status : ', order.status),
                    _previewRow('Valid : ', validText),
                    TextButton(onPressed: onClose, child: const Text('Close')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
