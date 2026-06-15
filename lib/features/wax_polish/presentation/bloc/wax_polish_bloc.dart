import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/wax_polish/domain/entities/wax_polish_service.dart';
import 'package:carrocare_flutter/features/wax_polish/domain/usecases/get_wax_polish_services_use_case.dart';

part 'wax_polish_event.dart';
part 'wax_polish_state.dart';

class WaxPolishBloc extends Bloc<WaxPolishEvent, WaxPolishState> {
  WaxPolishBloc(this._getWaxPolishServicesUseCase)
      : super(const WaxPolishInitial()) {
    on<WaxPolishRequested>(_onRequested);
  }

  final GetWaxPolishServicesUseCase _getWaxPolishServicesUseCase;

  Future<void> _onRequested(
    WaxPolishRequested event,
    Emitter<WaxPolishState> emit,
  ) async {
    emit(const WaxPolishLoading());
    try {
      final result = await _getWaxPolishServicesUseCase();
      emit(
        WaxPolishLoaded(
          description: result.$1,
          services: result.$2,
        ),
      );
    } catch (_) {
      emit(const WaxPolishFailure('Timeout.Try after sometime'));
    }
  }
}
