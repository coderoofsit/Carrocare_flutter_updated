import 'package:carrocare_flutter/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:carrocare_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:carrocare_flutter/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remoteDataSource);

  final ProfileRemoteDataSource _remoteDataSource;

  @override
  Future<UserProfile> getProfile({
    required String token,
    required String customerId,
  }) async {
    final data = await _remoteDataSource.getProfile(
      token: token,
      customerId: customerId,
    );
    final code = (data['code'] ?? '').toString();
    if (code == '201') {
      throw Exception('Session expired');
    }
    if (code != '200') {
      throw Exception((data['message'] ?? 'Failed to load profile').toString());
    }

    return UserProfile(
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      mobile: (data['mobile'] ?? '').toString(),
      apartmentName: (data['apartment_name'] ?? '').toString(),
      apartmentBuilding: (data['apartment_building'] ?? '').toString(),
      flatNo: (data['flat_no'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      gst: (data['gst'] ?? '').toString(),
      latitude: (data['latitude'] ?? '').toString(),
      longitude: (data['longitude'] ?? '').toString(),
      token: (data['token'] ?? token).toString(),
      customerId: (data['customer_id'] ?? customerId).toString(),
    );
  }

  @override
  Future<String> updateProfile({
    required String token,
    required String customerId,
    required String apartmentName,
    required String apartmentBuilding,
    required String flatNo,
    required String address,
    required String latitude,
    required String longitude,
    required String gst,
  }) async {
    final data = await _remoteDataSource.updateProfile(
      token: token,
      customerId: customerId,
      apartmentName: apartmentName,
      apartmentBuilding: apartmentBuilding,
      flatNo: flatNo,
      address: address,
      latitude: latitude,
      longitude: longitude,
      gst: gst,
    );
    final code = (data['code'] ?? '').toString();
    if (code != '200') {
      throw Exception((data['message'] ?? 'Failed to update profile').toString());
    }
    return (data['result'] ?? 'Profile updated').toString();
  }
}
