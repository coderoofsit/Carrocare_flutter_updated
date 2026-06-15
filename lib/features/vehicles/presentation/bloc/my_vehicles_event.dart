part of 'my_vehicles_bloc.dart';

sealed class MyVehiclesEvent {
  const MyVehiclesEvent();
}

class MyVehiclesRequested extends MyVehiclesEvent {
  const MyVehiclesRequested({
    required this.customerId,
    required this.token,
  });

  final String customerId;
  final String token;
}
