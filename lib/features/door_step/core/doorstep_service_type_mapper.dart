/// Maps doorstep pager / booking actions to backend `service_type` values.
class DoorstepServiceTypeMapper {
  DoorstepServiceTypeMapper._();

  static String serviceTypeForAction(String action) {
    switch (action) {
      case 'carwash':
        return 'Door step Wash';
      case 'detailing':
        return 'Door step Detailing';
      case 'painting':
        return 'Door step Painting';
      case 'battery':
        return 'Door step Battery';
      case 'machinePolish':
        return 'Door step Addon';
      default:
        return 'Door step Wash';
    }
  }
}
