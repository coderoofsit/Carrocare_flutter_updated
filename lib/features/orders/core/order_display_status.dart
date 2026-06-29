/// Customer-facing order status (distinct from raw DB `order_status` / wash status).
bool isDoorstepServiceTypeLabel(String serviceType) {
  final service = serviceType.trim().toLowerCase();
  if (service.contains('door step')) return true;
  if (service == 'disinsfection' || service == 'disinfection') return true;
  return const <String>{
    'car washing',
    'bike wash',
    'car waxing',
    'ac vent cleaning',
  }.contains(service);
}

String resolveOrderDisplayStatus({
  required String serviceType,
  required String status,
  required String paymentMode,
}) {
  final normalizedStatus = status.trim();
  if (normalizedStatus == 'Completed' ||
      normalizedStatus == 'Cancel Requested') {
    return normalizedStatus;
  }
  if (paymentMode.toLowerCase() == 'online' &&
      normalizedStatus.toLowerCase() == 'not completed') {
    return 'Paid';
  }
  final isDoorstep = isDoorstepServiceTypeLabel(serviceType);
  if (isDoorstep && normalizedStatus.toLowerCase() == 'paid') {
    return 'Paid';
  }
  return normalizedStatus.isEmpty ? 'Not Completed' : normalizedStatus;
}
