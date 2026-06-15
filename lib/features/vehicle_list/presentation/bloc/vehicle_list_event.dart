part of 'vehicle_list_bloc.dart';

sealed class VehicleListEvent {
  const VehicleListEvent();
}

class VehicleListRequested extends VehicleListEvent {
  const VehicleListRequested({
    required this.args,
    required this.customerId,
    required this.token,
  });

  final VehicleListArgs args;
  final String customerId;
  final String token;
}
