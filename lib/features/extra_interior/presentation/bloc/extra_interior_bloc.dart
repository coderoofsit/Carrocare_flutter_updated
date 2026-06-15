import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/extra_interior/domain/entities/extra_interior_service.dart';
import 'package:carrocare_flutter/features/extra_interior/domain/usecases/get_extra_interior_service_use_case.dart';

part 'extra_interior_event.dart';
part 'extra_interior_state.dart';

class ExtraInteriorBloc extends Bloc<ExtraInteriorEvent, ExtraInteriorState> {
  ExtraInteriorBloc(this._getExtraInteriorServiceUseCase)
      : super(const ExtraInteriorInitial()) {
    on<ExtraInteriorRequested>(_onRequested);
  }

  final GetExtraInteriorServiceUseCase _getExtraInteriorServiceUseCase;

  Future<void> _onRequested(
    ExtraInteriorRequested event,
    Emitter<ExtraInteriorState> emit,
  ) async {
    emit(const ExtraInteriorLoading());
    try {
      final service = await _getExtraInteriorServiceUseCase();
      emit(ExtraInteriorLoaded(service));
    } catch (_) {
      emit(const ExtraInteriorFailure('Timeout.Try after sometime'));
    }
  }
}
