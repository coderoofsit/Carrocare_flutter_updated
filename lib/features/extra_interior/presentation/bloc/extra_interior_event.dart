part of 'extra_interior_bloc.dart';

sealed class ExtraInteriorEvent {
  const ExtraInteriorEvent();
}

class ExtraInteriorRequested extends ExtraInteriorEvent {
  const ExtraInteriorRequested();
}
