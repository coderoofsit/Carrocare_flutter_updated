import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/usecases/get_daily_wash_services_use_case.dart';

part 'daily_wash_event.dart';
part 'daily_wash_state.dart';

class DailyWashBloc extends Bloc<DailyWashEvent, DailyWashState> {
  DailyWashBloc(this._getDailyWashServicesUseCase) : super(const DailyWashInitial()) {
    on<DailyWashRequested>(_onRequested);
  }

  final GetDailyWashServicesUseCase _getDailyWashServicesUseCase;

  Future<void> _onRequested(
    DailyWashRequested event,
    Emitter<DailyWashState> emit,
  ) async {
    emit(const DailyWashLoading());
    try {
      final result = await _getDailyWashServicesUseCase();
      emit(
        DailyWashLoaded(
          description: result.$1,
          services: result.$2,
        ),
      );
    } catch (_) {
      emit(const DailyWashFailure('Timeout.Try after sometime'));
    }
  }
}
