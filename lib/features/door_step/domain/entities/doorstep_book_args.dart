class DoorstepBookArgs {
  const DoorstepBookArgs({
    required this.packType,
    required this.packAmount,
    required this.serviceLabel,
    required this.action,
  });

  final String packType;
  final String packAmount;
  final String serviceLabel;
  final String action;
}
