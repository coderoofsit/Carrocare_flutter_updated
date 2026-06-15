part of 'bike_wash_bloc.dart';

sealed class BikeWashState {
  const BikeWashState();
}

class BikeWashInitial extends BikeWashState {
  const BikeWashInitial();
}

class BikeWashLoading extends BikeWashState {
  const BikeWashLoading();
}

class BikeWashLoaded extends BikeWashState {
  const BikeWashLoaded(this.service);

  final BikeWashService service;
}

class BikeWashFailure extends BikeWashState {
  const BikeWashFailure(this.message);

  final String message;
}
