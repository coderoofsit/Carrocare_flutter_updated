import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:carrocare_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Writes profile fields to SharedPreferences (used by ProfileBloc and post-login sync).
Future<void> persistProfileToPrefs(
  UserProfile profile,
  SharedPreferences prefs,
) async {
  await prefs.setString('token', profile.token);
  await prefs.setString('customer_id', profile.customerId);
  await prefs.setString('username', profile.name);
  await prefs.setString('name', profile.name);
  await prefs.setString('email', profile.email);
  await prefs.setString('usermobile', profile.mobile);
  await prefs.setString('mobile', profile.mobile);
  await prefs.setString('apartment_name', profile.apartmentName);
  await prefs.setString('apartment_building', profile.apartmentBuilding);
  await prefs.setString('flat_no', profile.flatNo);
  await prefs.setString('address', profile.address);
  await prefs.setString('gst', profile.gst);
  if (profile.latitude.isNotEmpty) {
    await prefs.setString('latitude', profile.latitude);
  }
  if (profile.longitude.isNotEmpty) {
    await prefs.setString('longitude', profile.longitude);
  }
}

/// Fetches profile from API and caches it locally (e.g. after login).
/// Failures are ignored so auth/navigation is not blocked.
Future<void> syncProfileFromServer({
  required String token,
  required String customerId,
}) async {
  if (token.isEmpty || customerId.isEmpty) return;
  try {
    final profile = await sl<ProfileRepository>().getProfile(
      token: token,
      customerId: customerId,
    );
    final prefs = await SharedPreferences.getInstance();
    await persistProfileToPrefs(profile, prefs);
  } catch (_) {}
}
