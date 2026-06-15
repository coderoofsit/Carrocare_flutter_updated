import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/features/vehicle_list/domain/entities/vehicle_list_args.dart';
import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
part 'vehicle_list_event.dart';
part 'vehicle_list_state.dart';

class VehicleListBloc extends Bloc<VehicleListEvent, VehicleListState> {
  VehicleListBloc(this._repository) : super(const VehicleListInitial()) {
    on<VehicleListRequested>(_onRequested);
  }

  final VehiclesRepository _repository;

  Future<void> _onRequested(
    VehicleListRequested event,
    Emitter<VehicleListState> emit,
  ) async {
    emit(const VehicleListLoading());
    try {
      final isExtraInterior = _isExtraInteriorFlow(event.args);
      final category = isExtraInterior
          ? ''
          : normalizeVehicleCategory(event.args.carName);
      final vehicles = await _repository.getVehiclesForBooking(
        customerId: event.customerId,
        token: event.token,
        category: category,
        extraInterior: isExtraInterior,
      );
      emit(
        VehicleListLoaded(
          args: event.args,
          vehicles: vehicles,
          hideBottomBar: isExtraInterior || _isExtraInteriorName(event.args.carName),
        ),
      );
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        emit(const VehicleListFailure('Session expired. Please login again.'));
        return;
      }
      emit(const VehicleListFailure('Timeout.Try after sometime'));
    }
  }

  bool _isExtraInteriorFlow(VehicleListArgs args) {
    return args.header.toLowerCase() == 'extra interior';
  }

  bool _isExtraInteriorName(String carName) {
    final lower = carName.toLowerCase();
    return lower.startsWith('extra');
  }
}
