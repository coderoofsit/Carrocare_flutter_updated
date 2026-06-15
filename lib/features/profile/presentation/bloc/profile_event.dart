part of 'profile_bloc.dart';

sealed class ProfileEvent {
  const ProfileEvent();
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested({
    required this.token,
    required this.customerId,
  });

  final String token;
  final String customerId;
}

class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({
    required this.token,
    required this.customerId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.apartmentName,
    required this.apartmentBuilding,
    required this.flatNo,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.gst,
  });

  final String token;
  final String customerId;
  final String name;
  final String email;
  final String mobile;
  final String apartmentName;
  final String apartmentBuilding;
  final String flatNo;
  final String address;
  final String latitude;
  final String longitude;
  final String gst;
}
