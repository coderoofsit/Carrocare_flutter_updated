part of 'wax_polish_bloc.dart';

sealed class WaxPolishEvent {
  const WaxPolishEvent();
}

class WaxPolishRequested extends WaxPolishEvent {
  const WaxPolishRequested();
}
