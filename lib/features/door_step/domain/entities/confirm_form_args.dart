enum ConfirmFormMode {
  insurance,
  machinePolish,
}

class ConfirmFormArgs {
  const ConfirmFormArgs({this.mode = ConfirmFormMode.machinePolish});

  final ConfirmFormMode mode;

  String get headerTitle => mode == ConfirmFormMode.insurance
      ? 'Doorstep Insurance'
      : 'Confirm Form';

  String get formField =>
      mode == ConfirmFormMode.insurance ? 'car_insurance' : 'car_machine_polish';

  String get servicePriceKey => mode == ConfirmFormMode.insurance
      ? 'doorstep car insurance'
      : 'doorstep car machine polish';
}
