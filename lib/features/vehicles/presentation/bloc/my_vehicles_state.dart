part of 'my_vehicles_bloc.dart';

sealed class MyVehiclesState {
  const MyVehiclesState();
}

class MyVehiclesInitial extends MyVehiclesState {
  const MyVehiclesInitial();
}

class MyVehiclesLoading extends MyVehiclesState {
  const MyVehiclesLoading();
}

class MyVehiclesLoaded extends MyVehiclesState {
  const MyVehiclesLoaded(this.vehicles);
  final List<VehicleItem> vehicles;
}

class MyVehiclesFailure extends MyVehiclesState {
  const MyVehiclesFailure(this.message);
  final String message;
}
