import 'package:carrocare_flutter/features/orders/domain/entities/payment_detail.dart';

class OrderItem {
  const OrderItem({    required this.dateAndTime,
    required this.orderId,
    required this.serviceType,
    required this.plan,
    required this.paymentType,
    required this.packageType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleNo,
    required this.vehicleId,
    required this.packageValue,
    required this.totalAmount,
    required this.gst,
    required this.gstAmount,
    required this.subTotalAmount,
    required this.discountAmount,
    required this.paymentMode,
    required this.valid,
    required this.paidCount,
    required this.nextDue,
    required this.status,
    required this.reason,
    required this.washDetails,
    required this.extraInterior,
    required this.cancelSubscription,
    required this.paymentHistory,
    required this.scheduleDate,
    required this.scheduleTime,
    required this.vehicleImage,
    required this.imageDateAndTime,
    required this.workDone,
    required this.invoice,
    required this.paymentDetails,
  });

  final String dateAndTime;
  final String orderId;
  final String serviceType;
  final String plan;
  final String paymentType;
  final String packageType;
  final String vehicleMake;
  final String vehicleModel;
  final String vehicleNo;
  final String vehicleId;
  final String packageValue;
  final String totalAmount;
  final String gst;
  final String gstAmount;
  final String subTotalAmount;
  final String discountAmount;
  final String paymentMode;
  final String valid;
  final String paidCount;
  final String nextDue;
  final String status;
  final String reason;
  final String washDetails;
  final String extraInterior;
  final String cancelSubscription;
  final String paymentHistory;
  final String scheduleDate;
  final String scheduleTime;
  final String vehicleImage;
  final String imageDateAndTime;
  final String workDone;
  final String invoice;
  final List<PaymentDetail> paymentDetails;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      dateAndTime: (json['date_and_time'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      serviceType: (json['service_type'] ?? '').toString(),
      plan: (json['plan'] ?? '').toString(),
      paymentType: (json['payment_type'] ?? '').toString(),
      packageType: (json['package_type'] ?? '').toString(),
      vehicleMake: (json['vehicle_make'] ?? '').toString(),
      vehicleModel: (json['vehicle_model'] ?? '').toString(),
      vehicleNo: (json['vehicle_no'] ?? '').toString(),
      vehicleId: (json['vehicle_id'] ?? '').toString(),
      packageValue: (json['package_value'] ?? '').toString(),
      totalAmount: (json['total_amount'] ?? '').toString(),
      gst: (json['gst'] ?? '').toString(),
      gstAmount: (json['gst_amount'] ?? '').toString(),
      subTotalAmount: (json['sub_total_amount'] ?? '').toString(),
      discountAmount: (json['discount_amount'] ?? '').toString(),
      paymentMode: (json['payment_mode'] ?? '').toString(),
      valid: (json['valid'] ?? '').toString(),
      paidCount: (json['paid_count'] ?? '').toString(),
      nextDue: (json['next_due'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      washDetails: (json['wash_details'] ?? '').toString(),
      extraInterior: (json['extra_interior'] ?? '').toString(),
      cancelSubscription: (json['cancel_subscription'] ?? '').toString(),
      paymentHistory: (json['payment_history'] ?? '').toString(),
      scheduleDate: (json['schedule_date'] ?? '').toString(),
      scheduleTime: (json['schedule_time'] ?? '').toString(),
      vehicleImage: (json['vehicle_image'] ?? '').toString(),
      imageDateAndTime: (json['image_date_and_time'] ?? '').toString(),
      workDone: (json['work_done'] ?? '').toString(),
      invoice: (json['invoice'] ?? '').toString(),
      paymentDetails: _parsePaymentDetails(json['payment_details']),
    );
  }

  static List<PaymentDetail> _parsePaymentDetails(dynamic raw) {
    if (raw == null || raw == '') return const <PaymentDetail>[];
    if (raw is Map) {
      return <PaymentDetail>[
        PaymentDetail.fromJson(
          raw.map((key, value) => MapEntry(key.toString(), value)),
        ),
      ];
    }
    if (raw is! List) return const <PaymentDetail>[];
    final details = <PaymentDetail>[];
    for (final item in raw) {
      if (item is! Map) continue;
      try {
        details.add(
          PaymentDetail.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return details;
  }
}
