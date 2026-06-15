part of 'extra_interior_bloc.dart';

sealed class ExtraInteriorState {
  const ExtraInteriorState();
}

class ExtraInteriorInitial extends ExtraInteriorState {
  const ExtraInteriorInitial();
}

class ExtraInteriorLoading extends ExtraInteriorState {
  const ExtraInteriorLoading();
}

class ExtraInteriorLoaded extends ExtraInteriorState {
  const ExtraInteriorLoaded(this.service);

  final ExtraInteriorService service;
}

class ExtraInteriorFailure extends ExtraInteriorState {
  const ExtraInteriorFailure(this.message);

  final String message;
}
