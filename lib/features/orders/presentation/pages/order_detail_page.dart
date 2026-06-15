import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/utils/invoice_download_helper.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/order_item.dart';
import 'package:carrocare_flutter/features/orders/domain/entities/payment_detail.dart';
import 'package:carrocare_flutter/features/orders/domain/repositories/orders_repository.dart';
import 'package:carrocare_flutter/features/orders/presentation/pages/wash_calendar_page.dart';
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

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: <Widget>[
          SafeArea(
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
                  const Expanded(
                    child: Text(
                      'ORDER DETAILS',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      Color(0xFFEA2C1F),
                      Color(0xFFFF5722),
                      Color(0xFFEE3131),
                    ],
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 10),
                          _DetailRow(label: 'Created at', value: _order.dateAndTime),
                          _DetailRow(label: 'Order Id', value: _order.orderId),
                          _DetailRow(
                            label: 'Service type',
                            value: _order.serviceType,
                          ),
                          _DetailRow(
                            label: 'Payment type',
                            value: _order.paymentType,
                          ),
                          _DetailRow(
                            label: 'Package type',
                            value: _order.packageType,
                          ),
                          if (ui.showVehicleMake)
                            _DetailRow(
                              label: 'Vehicle Make',
                              value: _order.vehicleMake,
                            ),
                          if (ui.showVehicleModel)
                            _DetailRow(
                              label: 'Vehicle Model',
                              value: _order.vehicleModel,
                            ),
                          if (ui.showVehicleNo)
                            _DetailRow(
                              label: 'Vehicle No',
                              value: _order.vehicleNo,
                            ),
                          if (ui.showVehicleId)
                            _DetailRow(
                              label: 'Vehicle Id',
                              value: _order.vehicleId,
                            ),
                          if (ui.showSchedule)
                            _DetailRow(
                              label: 'Schedule Date',
                              value: _order.scheduleDate,
                            ),
                          if (ui.showStatus)
                            _DetailRow(label: 'Status', value: _order.status),
                          if (ui.showWorkDone)
                            _DetailRow(
                              label: 'Work Done',
                              value: _order.workDone,
                            ),
                          if (ui.showPaymentMode)
                            _DetailRow(
                              label: 'Payment Mode',
                              value: _order.paymentMode,
                            ),
                          if (ui.showPaidCount)
                            _DetailRow(
                              label: 'Paid Count',
                              value: _order.paidCount,
                            ),
                          if (ui.showValid)
                            _DetailRow(label: 'Valid', value: ui.validText),
                          _pricingCard(
                            pricing: pricing,
                            showDiscount: ui.showDiscount,
                          ),
                          if (ui.showWashDetails || ui.showExtraInterior)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
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
                                    const SizedBox(width: 8),
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
                            ),
                          if (ui.showCancelSubscription)
                            _fullWidthButton(
                              'Cancel Subscription',
                              AppColors.primary,
                              _confirmCancelSubscription,
                            ),
                          if (ui.showViewHistory)
                            _fullWidthButton(
                              'View History',
                              const Color(0xFF54A46B),
                              () => setState(() => _showPaymentHistory = true),
                            ),
                          if (ui.showCancelOrder)
                            _fullWidthButton(
                              'Cancel Order',
                              AppColors.primary,
                              _cancelCodOrder,
                            ),
                          if (ui.showDownloadInvoice)
                            _fullWidthButton(
                              'Download Invoice',
                              const Color(0xFF54A46B),
                              () => _downloadInvoice(_order.invoice, _order.orderId),
                            ),
                          if (ui.showImageField) ...<Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Text(
                                    'Image Date : ',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _order.imageDateAndTime,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                              ),
                              child: Image.network(
                                _order.vehicleImage,
                                height: 250,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                  'assets/images/placeholder.png',
                                  height: 250,
                                  fit: BoxFit.contain,
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
                        onClose: () =>
                            setState(() => _showPaymentHistory = false),
                        onDownload: (PaymentDetail payment) {
                          _downloadInvoice(
                            payment.invoice,
                            payment.razorpayPaymentId,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x55000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _pricingCard({
    required OrderPricingDisplay pricing,
    required bool showDiscount,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            if (pricing.showPackageValue)
              _priceRow('Plan amount : ', pricing.packageValueLabel),
            if (showDiscount && _order.discountAmount.isNotEmpty)
              _priceRow('Discount : ', '₹ ${_order.discountAmount}'),
            _priceRow('Amount (excl. GST) : ', pricing.taxableLabel),
            if (pricing.gstPercent > 0 && pricing.gstAmount > 0) ...<Widget>[
              _priceRow('GST (${pricing.gstPercentLabel}) : ', pricing.gstAmountLabel),
            ],
            _priceRow('Total (incl. GST) : ', pricing.totalLabel),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: AppColors.black),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
        ],
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

  Widget _actionButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: 40,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _fullWidthButton(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.white, width: 2),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(width: 2, color: const Color(0xFF8F8F8F)),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
      color: const Color(0xFFEDEFF1),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                ),
                child: const Text(
                  'View Payment Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFFEDEFF1),
                  ),
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Payment Id')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Invoice')),
                  ],
                  rows: payments
                      .map(
                        (payment) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text(payment.paymentDate)),
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
              TextButton(
                onPressed: onClose,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
