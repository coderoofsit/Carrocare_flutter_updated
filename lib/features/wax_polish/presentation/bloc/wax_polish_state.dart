part of 'wax_polish_bloc.dart';

sealed class WaxPolishState {
  const WaxPolishState();
}

class WaxPolishInitial extends WaxPolishState {
  const WaxPolishInitial();
}

class WaxPolishLoading extends WaxPolishState {
  const WaxPolishLoading();
}

class WaxPolishLoaded extends WaxPolishState {
  const WaxPolishLoaded({
    required this.description,
    required this.services,
  });

  final String description;
  final List<WaxPolishService> services;
}

class WaxPolishFailure extends WaxPolishState {
  const WaxPolishFailure(this.message);

  final String message;
}
