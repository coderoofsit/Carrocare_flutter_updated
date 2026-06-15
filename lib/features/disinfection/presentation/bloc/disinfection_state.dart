part of 'disinfection_bloc.dart';

sealed class DisinfectionState {
  const DisinfectionState();
}

class DisinfectionInitial extends DisinfectionState {
  const DisinfectionInitial();
}

class DisinfectionLoading extends DisinfectionState {
  const DisinfectionLoading();
}

class DisinfectionLoaded extends DisinfectionState {
  const DisinfectionLoaded({
    required this.description,
    required this.services,
  });

  final String description;
  final List<DailyService> services;
}

class DisinfectionFailure extends DisinfectionState {
  const DisinfectionFailure(this.message);

  final String message;
}
