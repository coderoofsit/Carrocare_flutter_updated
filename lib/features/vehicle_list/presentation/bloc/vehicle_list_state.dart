part of 'vehicle_list_bloc.dart';

sealed class VehicleListState {
  const VehicleListState();
}

class VehicleListInitial extends VehicleListState {
  const VehicleListInitial();
}

class VehicleListLoading extends VehicleListState {
  const VehicleListLoading();
}

class VehicleListLoaded extends VehicleListState {
  const VehicleListLoaded({
    required this.args,
    required this.vehicles,
    required this.hideBottomBar,
  });

  final VehicleListArgs args;
  final List<VehicleItem> vehicles;
  final bool hideBottomBar;
}

class VehicleListFailure extends VehicleListState {
  const VehicleListFailure(this.message);

  final String message;
}
