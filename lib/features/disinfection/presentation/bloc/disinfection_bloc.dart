import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/daily_wash/domain/entities/daily_service.dart';
import 'package:carrocare_flutter/features/disinfection/domain/usecases/get_disinfection_services_use_case.dart';

part 'disinfection_event.dart';
part 'disinfection_state.dart';

class DisinfectionBloc extends Bloc<DisinfectionEvent, DisinfectionState> {
  DisinfectionBloc(this._useCase) : super(const DisinfectionInitial()) {
    on<DisinfectionRequested>(_onRequested);
  }

  final GetDisinfectionServicesUseCase _useCase;

  Future<void> _onRequested(
    DisinfectionRequested event,
    Emitter<DisinfectionState> emit,
  ) async {
    emit(const DisinfectionLoading());
    try {
      final result = await _useCase();
      emit(DisinfectionLoaded(description: result.$1, services: result.$2));
    } catch (_) {
      emit(const DisinfectionFailure('Timeout.Try after sometime'));
    }
  }
}
