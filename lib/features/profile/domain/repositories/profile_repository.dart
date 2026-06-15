import 'package:carrocare_flutter/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile({
    required String token,
    required String customerId,
  });

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
  });
}
