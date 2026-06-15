part of 'disinfection_bloc.dart';

sealed class DisinfectionEvent {
  const DisinfectionEvent();
}

class DisinfectionRequested extends DisinfectionEvent {
  const DisinfectionRequested();
}
