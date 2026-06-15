class BillingItem {
  const BillingItem({
    required this.downloadInvoice,
    required this.amount,
    required this.razorpayPaymentId,
    required this.invoice,
    required this.date,
  });

  final String downloadInvoice;
  final String amount;
  final String razorpayPaymentId;
  final String invoice;
  final String date;

  factory BillingItem.fromJson(Map<String, dynamic> json) {
    return BillingItem(
      downloadInvoice: (json['download_invoice'] ?? '').toString(),
      amount: (json['amount'] ?? '').toString(),
      razorpayPaymentId: (json['razorpay_payment_id'] ?? '').toString(),
      invoice: (json['invoice'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
    );
  }

  bool get canDownload {
    if (downloadInvoice.isEmpty) return false;
    final parts = downloadInvoice.split('=');
    if (parts.length < 2) return false;
    return parts.last.trim() != '0';
  }
}
