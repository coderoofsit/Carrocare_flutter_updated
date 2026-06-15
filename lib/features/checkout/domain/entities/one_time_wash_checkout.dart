class OneTimeWashCheckout {
  const OneTimeWashCheckout({
    required this.discountAmount,
    required this.fineAmount,
    required this.gstAmount,
    required this.orderExists,
    required this.totalAmount,
  });

  final String discountAmount;
  final String fineAmount;
  final String gstAmount;
  final String orderExists;
  final String totalAmount;

  factory OneTimeWashCheckout.fromJson(Map<String, dynamic> json) {
    return OneTimeWashCheckout(
      discountAmount: (json['discount_amount'] ?? '0').toString(),
      fineAmount: (json['fine_amount'] ?? '0').toString(),
      gstAmount: (json['gst_amount'] ?? '0').toString(),
      orderExists: (json['order_exists'] ?? '0').toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
    );
  }
}
