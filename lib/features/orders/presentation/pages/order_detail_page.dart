import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_decorations.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/animated_gradient_badge.dart';
import 'package:carrocare_flutter/core/widgets/bill_summary_card.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:carrocare_flutter/core/widgets/dotted_loader.dart';
import 'package:carrocare_flutter/core/utils/invoice_download_helper.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/payment_detail.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:carrocare_flutter/features/orders/presentation/pages/wash_calendar_page.dart';
import 'package:carrocare_flutter/features/orders/presentation/utils/order_date_time_display.dart';
import 'package:carrocare_flutter/features/orders/presentation/utils/order_pricing_display.dart';
import 'package:carrocare_flutter/features/orders/presentation/widgets/cancel_order_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetailArgs {
  const OrderDetailArgs({
    required this.order,
    required this.orders,
    required this.index,
  });

  final OrderItem order;
  final List<OrderItem> orders;
  final int index;
}

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.args});

  final OrderDetailArgs args;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _showPaymentHistory = false;
  bool _busy = false;

  final OrdersRepository _ordersRepository = sl<OrdersRepository>();
  final InvoiceDownloadHelper _invoiceHelper = InvoiceDownloadHelper();

  OrderItem get _order => widget.args.order;

  @override
  Widget build(BuildContext context) {
    final ui = _OrderDetailUi.fromOrder(_order);
    final pricing = OrderPricingDisplay.fromOrder(_order);

    return CarroCareScaffold(
      title: 'Order Details',
      onBack: () => context.pop(),
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _OrderDetailsCard(
                  order: _order,
                  ui: ui,
                ),
                const SizedBox(height: 16),
                _pricingCard(
                  pricing: pricing,
                  showDiscount: ui.showDiscount,
                ),
                if (ui.showWashDetails || ui.showExtraInterior) ...<Widget>[
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      if (ui.showWashDetails)
                        Expanded(
                          child: _actionButton(
                            'Wash Details',
                            () => context.push(
                              '/wash-calendar',
                              extra: WashCalendarArgs(
                                vehicleId: _order.vehicleId,
                                orderId: _order.orderId,
                                type: 'wash',
                              ),
                            ),
                          ),
                        ),
                      if (ui.showWashDetails && ui.showExtraInterior)
                        const SizedBox(width: 12),
                      if (ui.showExtraInterior)
                        Expanded(
                          child: _actionButton(
                            'Extra Interior',
                            () => context.push(
                              '/wash-calendar',
                              extra: WashCalendarArgs(
                                vehicleId: _order.vehicleId,
                                orderId: _order.orderId,
                                type: 'extra',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (ui.showCancelSubscription)
                  _fullWidthButton(
                    'Cancel Subscription',
                    _confirmCancelSubscription,
                  ),
                if (ui.showViewHistory)
                  _fullWidthButton(
                    'View History',
                    () => setState(() => _showPaymentHistory = true),
                  ),
                if (ui.showCancelOrder)
                  _fullWidthButton('Cancel Order', _cancelCodOrder),
                if (ui.showDownloadInvoice)
                  _fullWidthButton(
                    'Download Invoice',
                    () => _downloadInvoice(_order.invoice, _order.orderId),
                  ),
                if (ui.showImageField) ...<Widget>[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _OrderInfoBlock(
                            label: 'Image Date',
                            value: OrderDateTimeDisplay.formatDateTime(
                              _order.imageDateAndTime,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDecorations.inputRadius,
                            ),
                            child: Image.network(
                              _order.vehicleImage,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/images/placeholder.png',
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_showPaymentHistory)
            _PaymentHistoryOverlay(
              payments: _order.paymentDetails,
              onClose: () => setState(() => _showPaymentHistory = false),
              onDownload: (PaymentDetail payment) {
                _downloadInvoice(
                  payment.invoice,
                  payment.razorpayPaymentId,
                );
              },
            ),
          if (_busy)
            const ColoredBox(
              color: Color(0x55000000),
              child: CarroCareLoadingOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _pricingCard({
    required OrderPricingDisplay pricing,
    required bool showDiscount,
  }) {
    final lines = <BillLine>[
      if (pricing.showPackageValue)
        BillLine(label: 'Plan amount', amount: pricing.packageValueLabel),
      if (showDiscount && _order.discountAmount.isNotEmpty)
        BillLine(label: 'Discount', amount: '₹ ${_order.discountAmount}'),
      BillLine(label: 'Amount (excl. GST)', amount: pricing.taxableLabel),
      if (pricing.gstPercent > 0 && pricing.gstAmount > 0)
        BillLine(
          label: 'GST (${pricing.gstPercentLabel})',
          amount: pricing.gstAmountLabel,
        ),
    ];

    return BillSummaryCard(
      title: 'Payment Summary',
      lines: lines,
      totalLabel: 'Total (incl. GST)',
      totalAmount: pricing.totalLabel,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: _buttonStyle(fullWidth: false),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _fullWidthButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: _buttonStyle(),
          child: Text(label),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle({bool fullWidth = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      minimumSize: Size(fullWidth ? double.infinity : 0, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDecorations.buttonRadius),
      ),
      textStyle: AppTypography.quicksand(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      ),
    );
  }

  Future<void> _downloadInvoice(String url, String fileId) async {
    await _invoiceHelper.downloadAndOpen(
      context: context,
      downloadUrl: url,
      fileName: 'Carrocare_Invoice_$fileId.pdf',
    );
  }

  Future<void> _confirmCancelSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm!'),
        content: const Text('Do you want to cancel subscription?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      final message = await _ordersRepository.cancelSubscription(
        token: prefs.getString('token') ?? '',
        vehicleId: _order.vehicleId,
        orderId: _order.orderId,
      );
      if (!mounted) return;
      _showSnack(message);
      context.go('/my-orders');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelCodOrder() async {
    final reason = await showCancelOrderDialog(context);
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      final message = await _ordersRepository.cancelCodOrder(
        orderId: _order.orderId,
        customerId: prefs.getString('customer_id') ?? '',
        reason: reason,
      );
      if (!mounted) return;
      _showSnack(message);
      context.go('/my-orders');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _OrderDetailsCard extends StatelessWidget {
  const _OrderDetailsCard({
    required this.order,
    required this.ui,
  });

  final OrderItem order;
  final _OrderDetailUi ui;

  @override
  Widget build(BuildContext context) {
    final paymentType = order.paymentType.toLowerCase();
    final chipLabel = paymentType == 'monthly' ? 'Monthly · Autopay' : 'One-time';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                AnimatedGradientBadge(
                  label: chipLabel,
                  vibrant: paymentType == 'monthly',
                ),
                const Spacer(),
                if (ui.showStatus)
                  Text(
                    order.displayStatus.toUpperCase(),
                    style: AppTypography.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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
            _OrderInfoBlock(
              label: 'Created at',
              value: OrderDateTimeDisplay.formatDateTime(order.dateAndTime),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _OrderInfoBlock(
              label: 'Order Id',
              value: order.orderId,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _OrderInfoBlock(
                    label: 'Service type',
                    value: order.serviceType,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OrderInfoBlock(
                    label: 'Payment type',
                    value: order.paymentType,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _OrderInfoBlock(label: 'Package type', value: order.packageType),
            if (ui.showVehicleMake || ui.showVehicleModel) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (ui.showVehicleMake)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Vehicle Make',
                        value: order.vehicleMake,
                      ),
                    ),
                  if (ui.showVehicleMake && ui.showVehicleModel)
                    const SizedBox(width: 12),
                  if (ui.showVehicleModel)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Vehicle Model',
                        value: order.vehicleModel,
                      ),
                    ),
                ],
              ),
            ],
            if (ui.showVehicleNo || ui.showVehicleId) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (ui.showVehicleNo)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Vehicle No',
                        value: order.vehicleNo,
                      ),
                    ),
                  if (ui.showVehicleNo && ui.showVehicleId)
                    const SizedBox(width: 12),
                  if (ui.showVehicleId)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Vehicle Id',
                        value: order.vehicleId,
                      ),
                    ),
                ],
              ),
            ],
            if (ui.showSchedule) ...<Widget>[
              const SizedBox(height: 12),
              _OrderInfoBlock(
                label: 'Schedule Date',
                value: order.scheduleDate,
              ),
            ],
            if (ui.showWorkDone || ui.showPaymentMode) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (ui.showWorkDone)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Work Done',
                        value: order.workDone,
                      ),
                    ),
                  if (ui.showWorkDone && ui.showPaymentMode)
                    const SizedBox(width: 12),
                  if (ui.showPaymentMode)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Payment Mode',
                        value: order.paymentMode,
                      ),
                    ),
                ],
              ),
            ],
            if (ui.showPaidCount || ui.showValid) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (ui.showPaidCount)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Paid Count',
                        value: order.paidCount,
                      ),
                    ),
                  if (ui.showPaidCount && ui.showValid)
                    const SizedBox(width: 12),
                  if (ui.showValid)
                    Expanded(
                      child: _OrderInfoBlock(
                        label: 'Valid',
                        value: ui.validText,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderInfoBlock extends StatelessWidget {
  const _OrderInfoBlock({
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '—' : value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: AppTypography.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: AppTypography.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.grey800,
            height: 1.3,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _OrderDetailUi {
  const _OrderDetailUi({
    required this.showVehicleMake,
    required this.showVehicleModel,
    required this.showVehicleNo,
    required this.showVehicleId,
    required this.showSchedule,
    required this.showStatus,
    required this.showWorkDone,
    required this.showPaymentMode,
    required this.showPaidCount,
    required this.showValid,
    required this.showDiscount,
    required this.showWashDetails,
    required this.showExtraInterior,
    required this.showCancelSubscription,
    required this.showViewHistory,
    required this.showDownloadInvoice,
    required this.showCancelOrder,
    required this.showImageField,
    required this.validText,
  });

  final bool showVehicleMake;
  final bool showVehicleModel;
  final bool showVehicleNo;
  final bool showVehicleId;
  final bool showSchedule;
  final bool showStatus;
  final bool showWorkDone;
  final bool showPaymentMode;
  final bool showPaidCount;
  final bool showValid;
  final bool showDiscount;
  final bool showWashDetails;
  final bool showExtraInterior;
  final bool showCancelSubscription;
  final bool showViewHistory;
  final bool showDownloadInvoice;
  final bool showCancelOrder;
  final bool showImageField;
  final String validText;

  factory _OrderDetailUi.fromOrder(OrderItem order) {
    final service = order.serviceType.toLowerCase();
    final paymentType = order.paymentType.toLowerCase();
    final showDiscount = order.discountAmount != '0' &&
        order.discountAmount.isNotEmpty;

    var showVehicleMake = true;
    var showVehicleModel = true;
    var showVehicleNo = true;
    var showVehicleId = true;
    var showSchedule = false;
    var showStatus = true;
    var showWorkDone = true;
    var showPaymentMode = true;
    var showPaidCount = true;
    var showValid = true;
    var showWashDetails = false;
    var showExtraInterior = false;
    var showCancelSubscription = false;
    var showViewHistory = false;
    var showDownloadInvoice = false;
    var showCancelOrder = false;
    var showImageField = false;
    var validText = order.valid;

    if (service == 'addon' && paymentType == 'one time') {
      showVehicleMake = true;
      showVehicleModel = true;
      showVehicleNo = true;
      showVehicleId = true;
      showSchedule = true;
      showStatus = true;
      showWorkDone = true;
      showPaymentMode = true;
      showPaidCount = false;
      showValid = false;
      showDownloadInvoice = true;
      showImageField = order.workDone.toLowerCase() != 'no';
    } else if (service == 'addon' && paymentType == 'monthly') {
      showWashDetails = _flagVisible(order.washDetails);
      if (order.washDetails == '0') {
        validText = order.valid;
      } else if (order.washDetails == '1') {
        validText = order.nextDue;
      }
      showExtraInterior = order.extraInterior == '1';
      showCancelSubscription = order.cancelSubscription == '1';
      if (order.paymentHistory == '1') {
        showViewHistory = true;
      } else {
        showDownloadInvoice = true;
      }
    } else if (service == 'wash') {
      showWashDetails = _flagVisible(order.washDetails);
      if (order.washDetails == '0') {
        validText = order.valid;
      } else if (order.washDetails == '1') {
        validText = order.nextDue;
      }
      showExtraInterior = order.extraInterior == '1';
      showCancelSubscription = order.cancelSubscription == '1';
      if (order.paymentHistory == '1') {
        showViewHistory = true;
      } else {
        showDownloadInvoice = true;
      }
      if (order.packageType.toLowerCase() == 'bike' ||
          order.plan.toLowerCase() == 'bike') {
        showWashDetails = false;
      }
    } else if (_isDoorStep(service)) {
      showVehicleMake = true;
      showVehicleModel = true;
      showVehicleNo = true;
      showVehicleId = true;
      showSchedule = true;
      showStatus = true;
      showPaymentMode = true;
      showPaidCount = false;
      showValid = false;
      showDownloadInvoice = true;
      showCancelOrder = order.status != 'Cancel Requested';
    } else if (service == 'disinsfection' || service == 'disinfection') {
      showVehicleMake = true;
      showVehicleModel = true;
      showVehicleNo = true;
      showVehicleId = true;
      showSchedule = true;
      showStatus = true;
      showPaymentMode = true;
      showPaidCount = false;
      showValid = false;
      showDownloadInvoice = true;
    }

    return _OrderDetailUi(
      showVehicleMake: showVehicleMake,
      showVehicleModel: showVehicleModel,
      showVehicleNo: showVehicleNo,
      showVehicleId: showVehicleId,
      showSchedule: showSchedule,
      showStatus: showStatus,
      showWorkDone: showWorkDone,
      showPaymentMode: showPaymentMode,
      showPaidCount: showPaidCount,
      showValid: showValid,
      showDiscount: showDiscount,
      showWashDetails: showWashDetails,
      showExtraInterior: showExtraInterior,
      showCancelSubscription: showCancelSubscription,
      showViewHistory: showViewHistory,
      showDownloadInvoice: showDownloadInvoice,
      showCancelOrder: showCancelOrder,
      showImageField: showImageField,
      validText: validText,
    );
  }

  static bool _flagVisible(String value) =>
      value == '0' || value == '1';

  static bool _isDoorStep(String service) {
    return service == 'door step wash' ||
        service == 'door step detailing' ||
        service == 'door step addon';
  }
}

class _PaymentHistoryOverlay extends StatelessWidget {
  const _PaymentHistoryOverlay({
    required this.payments,
    required this.onClose,
    required this.onDownload,
  });

  final List<PaymentDetail> payments;
  final VoidCallback onClose;
  final void Function(PaymentDetail payment) onDownload;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.scrim,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDecorations.cardRadius),
                  ),
                ),
                child: Text(
                  'View Payment Details',
                  textAlign: TextAlign.center,
                  style: AppTypography.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppColors.grey50),
                  columns: <DataColumn>[
                    DataColumn(
                      label: Text(
                        'Date',
                        style: AppTypography.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Payment Id',
                        style: AppTypography.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Amount',
                        style: AppTypography.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: AppTypography.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Invoice',
                        style: AppTypography.dmSans(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                  rows: payments
                      .map(
                        (payment) => DataRow(
                          cells: <DataCell>[
                            DataCell(
                              Text(
                                OrderDateTimeDisplay.formatDateTime(
                                  payment.paymentDate,
                                ),
                              ),
                            ),
                            DataCell(Text(payment.razorpayPaymentId)),
                            DataCell(Text(payment.amount)),
                            DataCell(Text(payment.status)),
                            DataCell(
                              TextButton(
                                onPressed: () => onDownload(payment),
                                child: const Text('Download'),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDecorations.buttonRadius,
                        ),
                      ),
                    ),
                    child: const Text('Close'),
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
