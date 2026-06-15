class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    required this.mobile,
    required this.apartmentName,
    required this.apartmentBuilding,
    required this.flatNo,
    required this.address,
    required this.gst,
    required this.latitude,
    required this.longitude,
    required this.token,
    required this.customerId,
  });

  final String name;
  final String email;
  final String mobile;
  final String apartmentName;
  final String apartmentBuilding;
  final String flatNo;
  final String address;
  final String gst;
  final String latitude;
  final String longitude;
  final String token;
  final String customerId;
}
