class PaymentDetail {
  const PaymentDetail({
    required this.paymentDate,
    required this.razorpayPaymentId,
    required this.amount,
    required this.status,
    required this.invoice,
  });

  final String paymentDate;
  final String razorpayPaymentId;
  final String amount;
  final String status;
  final String invoice;

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      paymentDate: (json['payment_date'] ?? '').toString(),
      razorpayPaymentId: (json['razorpay_payment_id'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      invoice: (json['invoice'] ?? '').toString(),
    );
  }
}
