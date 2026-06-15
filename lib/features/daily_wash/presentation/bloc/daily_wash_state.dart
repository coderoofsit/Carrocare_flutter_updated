part of 'daily_wash_bloc.dart';

sealed class DailyWashState {
  const DailyWashState();
}

class DailyWashInitial extends DailyWashState {
  const DailyWashInitial();
}

class DailyWashLoading extends DailyWashState {
  const DailyWashLoading();
}

class DailyWashLoaded extends DailyWashState {
  const DailyWashLoaded({
    required this.description,
    required this.services,
  });

  final String description;
  final List<DailyService> services;
}

class DailyWashFailure extends DailyWashState {
  const DailyWashFailure(this.message);

  final String message;
}
