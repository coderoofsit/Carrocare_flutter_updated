/// Customer-facing order status (distinct from raw DB `order_status` / wash status).
String resolveOrderDisplayStatus({
  required String serviceType,
  required String status,
  required String paymentMode,
}) {
  final service = serviceType.toLowerCase();
  final isDoorstep = service.contains('door step') ||
      service == 'disinsfection' ||
      service == 'disinfection';
  if (!isDoorstep) {
    return status;
  }
  final normalizedStatus = status.trim();
  if (normalizedStatus == 'Completed' ||
      normalizedStatus == 'Cancel Requested') {
    return normalizedStatus;
  }
  if (paymentMode.toLowerCase() == 'online' &&
      normalizedStatus.toLowerCase() == 'not completed') {
    return 'Paid';
  }
  return normalizedStatus.isEmpty ? 'Not Completed' : normalizedStatus;
}
