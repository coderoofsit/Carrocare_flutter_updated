import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';

part 'my_vehicles_event.dart';
part 'my_vehicles_state.dart';

class MyVehiclesBloc extends Bloc<MyVehiclesEvent, MyVehiclesState> {
  MyVehiclesBloc(this._repository) : super(const MyVehiclesInitial()) {
    on<MyVehiclesRequested>(_onRequested);
  }

  final VehiclesRepository _repository;

  Future<void> _onRequested(
    MyVehiclesRequested event,
    Emitter<MyVehiclesState> emit,
  ) async {
    emit(const MyVehiclesLoading());
    try {
      final vehicles = await _repository.getMyVehicles(
        customerId: event.customerId,
        token: event.token,
      );
      emit(MyVehiclesLoaded(vehicles));
    } catch (_) {
      emit(const MyVehiclesFailure('Timeout.Try after sometime'));
    }
  }
}
