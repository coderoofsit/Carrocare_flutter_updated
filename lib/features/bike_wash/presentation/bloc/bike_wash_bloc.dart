import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/entities/bike_wash_service.dart';
import 'package:carrocare_flutter/features/bike_wash/domain/usecases/get_bike_wash_service_use_case.dart';

part 'bike_wash_event.dart';
part 'bike_wash_state.dart';

class BikeWashBloc extends Bloc<BikeWashEvent, BikeWashState> {
  BikeWashBloc(this._getBikeWashServiceUseCase) : super(const BikeWashInitial()) {
    on<BikeWashRequested>(_onRequested);
  }

  final GetBikeWashServiceUseCase _getBikeWashServiceUseCase;

  Future<void> _onRequested(
    BikeWashRequested event,
    Emitter<BikeWashState> emit,
  ) async {
    emit(const BikeWashLoading());
    try {
      final service = await _getBikeWashServiceUseCase();
      emit(BikeWashLoaded(service));
    } catch (_) {
      emit(const BikeWashFailure('Timeout.Try after sometime'));
    }
  }
}
