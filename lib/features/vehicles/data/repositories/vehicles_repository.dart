import 'package:carrocare_flutter/features/vehicles/core/vehicle_category_utils.dart';
import 'package:carrocare_flutter/features/vehicles/data/datasources/vehicles_remote_data_source.dart';
import 'package:carrocare_flutter/features/vehicles/domain/entities/vehicle_item.dart';

class VehiclesRepository {  VehiclesRepository(this._remote);

  final VehiclesRemoteDataSource _remote;

  Future<List<VehicleItem>> getMyVehicles({
    required String customerId,
    required String token,
  }) async {
    final data = await _remote.myVehicles(customerId: customerId, token: token);
    return _parseVehicleList(data);
  }

  Future<List<VehicleItem>> getVehiclesForBooking({
    required String customerId,
    required String token,
    required String category,
    required bool extraInterior,
  }) async {
    final normalizedCategory = normalizeVehicleCategory(category);

    if (extraInterior) {
      final data = await _remote.vehiclesForBooking(
        customerId: customerId,
        token: token,
        category: '',
        extraInterior: true,
      );
      return _parseVehicleList(data);
    }

    final filteredData = await _remote.vehiclesForBooking(
      customerId: customerId,
      token: token,
      category: normalizedCategory,
      extraInterior: false,
    );
    var vehicles = _parseVehicleList(filteredData);

    if (vehicles.isEmpty && normalizedCategory.isNotEmpty) {
      final allData = await _remote.myVehicles(
        customerId: customerId,
        token: token,
      );
      final allVehicles = _parseVehicleList(allData);
      vehicles = allVehicles
          .where(
            (vehicle) => vehicleCategoryMatches(
              vehicle.category,
              normalizedCategory,
            ),
          )
          .toList();
    }

    return vehicles;
  }

  List<VehicleItem> _parseVehicleList(Map<String, dynamic> data) {
    final code = (data['code'] ?? '').toString();
    if (code == '201') return <VehicleItem>[];
    if (code == '203') {
      throw Exception('Session expired');
    }
    final details = data['details'];
    if (details is! List) return <VehicleItem>[];
    return details.whereType<Map>().map((item) {
      final map = item.map((key, value) => MapEntry(key.toString(), value));
      return VehicleItem(
        id: (map['vehicle_id'] ?? '').toString(),
        make: (map['vehicle_make'] ?? '').toString(),
        model: (map['vehicle_model'] ?? '').toString(),
        vehicleNo: (map['vehicle_no'] ?? '').toString(),
        color: (map['vehicle_color'] ?? '').toString(),
        apartmentName: (map['vehicle_apartment_name'] ?? '').toString(),
        parkingLotNo: (map['vehicle_parking_lot_no'] ?? '').toString(),
        parkingArea: (map['vehicle_parking_area'] ?? '').toString(),
        preferredSchedule: (map['vehicle_preferred_schedule'] ?? '').toString(),
        preferredTime: (map['vehicle_preferred_time'] ?? '').toString(),
        image: (map['vehicle_image'] ?? '').toString(),
        category: (map['vehicle_category'] ?? '').toString(),
        vehicleType: (map['vehicle_type'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<String>> getApartmentNames() async {
    final data = await _remote.apartmentList();
    final list = data['Apartment'];
    if (list is! List) return <String>[];
    return list
        .whereType<Map>()
        .map((e) => (e['name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<List<String>> getParkingAreas() async {
    final data = await _remote.parkingAreaList();
    final list = data['data'];
    if (list is! List) return <String>[];
    return list
        .whereType<Map>()
        .map((e) => (e['name'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<List<String>> getMakeModels(String category) async {
    final data = await _remote.makeModel(category);
    final list = data['vehicle'];
    if (list is! List) return <String>[];
    return list.whereType<Map>().map((e) {
      final make = (e['vehicle_make'] ?? '').toString();
      final model = (e['vehicle_model'] ?? '').toString();
      return '$make-$model';
    }).where((e) => e != '-').toList();
  }

  Future<String> addVehicle({
    required String vehicleType,
    required String category,
    required String make,
    required String model,
    required String vehicleNo,
    required String color,
    required String apartmentName,
    required String parkingLotNo,
    required String parkingArea,
    required String preferredSchedule,
    required String preferredTime,
    required String customerId,
    required String token,
  }) async {
    final data = await _remote.addVehicle(
      vehicleType: vehicleType,
      category: category,
      make: make,
      model: model,
      vehicleNo: vehicleNo,
      color: color,
      apartmentName: apartmentName,
      parkingLotNo: parkingLotNo,
      parkingArea: parkingArea,
      preferredSchedule: preferredSchedule,
      preferredTime: preferredTime,
      customerId: customerId,
      token: token,
    );
    final code = (data['code'] ?? '').toString();
    final message = (data['message'] ?? '').toString();
    if (code == '200') {
      return message.isEmpty ? 'Vehicle added successfully' : message;
    }
    throw Exception(message.isEmpty ? 'Failed to add vehicle' : message);
  }

  Future<String> addDoorstepVehicle({
    required String category,
    required String make,
    required String model,
    required String vehicleNo,
    required String color,
    required String customerId,
    required String token,
  }) async {
    final data = await _remote.addDoorstepVehicle(
      vehicleType: 'car',
      category: category,
      make: make,
      model: model,
      vehicleNo: vehicleNo,
      color: color,
      customerId: customerId,
      token: token,
    );
    final code = (data['code'] ?? '').toString();
    final message = (data['message'] ?? '').toString();
    if (code == '200') {
      return message.isEmpty ? 'Vehicle added successfully' : message;
    }
    throw Exception(message.isEmpty ? 'Failed to add vehicle' : message);
  }
}
