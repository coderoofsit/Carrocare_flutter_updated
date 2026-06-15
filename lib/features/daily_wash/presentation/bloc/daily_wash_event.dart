part of 'daily_wash_bloc.dart';

sealed class DailyWashEvent {
  const DailyWashEvent();
}

class DailyWashRequested extends DailyWashEvent {
  const DailyWashRequested();
}
