class LoginResponseModel {
  const LoginResponseModel({
    required this.code,
    required this.message,
    this.token,
    this.accessToken,
    this.refreshToken,
    this.customerId,
    this.name,
    this.mobile,
    this.email,
    this.status,
  });

  final String code;
  final String message;
  final String? token;
  final String? accessToken;
  final String? refreshToken;
  final String? customerId;
  final String? name;
  final String? mobile;
  final String? email;
  final String? status;

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      code: (json['code'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      token: json['token']?.toString(),
      accessToken: json['access_token']?.toString(),
      refreshToken: json['refresh_token']?.toString(),
      customerId: json['customer_id']?.toString(),
      name: json['name']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString(),
    );
  }
}
