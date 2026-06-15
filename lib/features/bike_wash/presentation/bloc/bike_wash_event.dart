part of 'bike_wash_bloc.dart';

sealed class BikeWashEvent {
  const BikeWashEvent();
}

class BikeWashRequested extends BikeWashEvent {
  const BikeWashRequested();
}
