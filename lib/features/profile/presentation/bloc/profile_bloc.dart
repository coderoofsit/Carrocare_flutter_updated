import 'package:bloc/bloc.dart';
import 'package:carrocare_flutter/core/utils/profile_prefs_sync.dart';
import 'package:carrocare_flutter/features/profile/domain/entities/user_profile.dart';
import 'package:carrocare_flutter/features/profile/domain/repositories/profile_repository.dart';
import 'package:carrocare_flutter/features/vehicles/data/repositories/vehicles_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Matches Android [ProfileActivity] visibility rules using saved service type
/// and loaded profile data (not transient home navigation).
String resolveProfileFormUserType({
  required String prefUserWants,
  required UserProfile profile,
  String? profileLoadFrom,
}) {
  final loadFrom = (profileLoadFrom ?? '').toLowerCase();
  if (loadFrom == 'main') {
    return 'apartment';
  }

  final apartmentName = profile.apartmentName.trim();
  if (apartmentName.isNotEmpty && apartmentName.toLowerCase() != 'null') {
    return 'apartment';
  }

  final pref = prefUserWants.trim().toLowerCase();
  final hasAddress = profile.address.trim().isNotEmpty;

  if (pref == 'doorstep' && hasAddress) {
    return 'doorstep';
  }

  return 'apartment';
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._profileRepository, this._vehiclesRepository)
      : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
  }

  final ProfileRepository _profileRepository;
  final VehiclesRepository _vehiclesRepository;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefUserWants = prefs.getString('user_wants') ?? 'apartment';
      final profileLoadFrom = prefs.getString('profile_load_from');
      final profile = await _profileRepository.getProfile(
        token: event.token,
        customerId: event.customerId,
      );
      final apartments = await _vehiclesRepository.getApartmentNames();
      await persistProfileToPrefs(profile, prefs);
      final userType = resolveProfileFormUserType(
        prefUserWants: prefUserWants,
        profile: profile,
        profileLoadFrom: profileLoadFrom,
      );
      emit(
        ProfileLoaded(
          profile: profile,
          apartments: apartments,
          userType: userType,
        ),
      );
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        emit(const ProfileFailure('Session expired. Please login again.'));
        return;
      }
      emit(const ProfileFailure('Timeout.Try after sometime'));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileUpdating(current));
    try {
      final message = await _profileRepository.updateProfile(
        token: event.token,
        customerId: event.customerId,
        apartmentName: event.apartmentName,
        apartmentBuilding: event.apartmentBuilding,
        flatNo: event.flatNo,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        gst: event.gst,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('apartment_name', event.apartmentName);
      await prefs.setString('apartment_building', event.apartmentBuilding);
      await prefs.setString('flat_no', event.flatNo);
      await prefs.setString('address', event.address);
      await prefs.setString('username', event.name);
      await prefs.setString('name', event.name);
      await prefs.setString('usermobile', event.mobile);
      await prefs.setString('mobile', event.mobile);
      await prefs.setString('email', event.email);
      if (event.latitude.isNotEmpty) {
        await prefs.setString('latitude', event.latitude);
      }
      if (event.longitude.isNotEmpty) {
        await prefs.setString('longitude', event.longitude);
      }
      emit(ProfileUpdateSuccess(message));
    } catch (e) {
      emit(
        ProfileLoaded(
          profile: current.profile,
          apartments: current.apartments,
          userType: current.userType,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

}
