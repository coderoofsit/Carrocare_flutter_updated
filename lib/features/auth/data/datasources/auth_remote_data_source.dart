import 'package:carrocare_flutter/core/network/api_client.dart';
import 'package:carrocare_flutter/core/utils/otp_utils.dart';
import 'package:carrocare_flutter/features/auth/data/models/login_response_model.dart';
import 'package:carrocare_flutter/features/auth/data/models/otp_send_result.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'login.php',
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );
    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<LoginResponseModel> register({
    required String mobile,
    required String password,
    required String name,
    required String email,
    required String otp,
    required String deviceId,
    required String deviceName,
    required String deviceModel,
    required String osVersion,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'register.php',
      data: <String, dynamic>{
        'mobile': mobile.trim(),
        'password': password,
        'name': name.trim(),
        'email': email.trim(),
        'otp': otp.trim(),
        'device_id': deviceId,
        'device_name': deviceName,
        'device_model': deviceModel,
        'os_version': osVersion,
      },
    );
    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> loginVerify({
    required String email,
    required String firebaseInstanceId,
    required String deviceName,
    required String deviceModel,
    required String osVersion,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'login-verify.php',
      data: <String, dynamic>{
        'email': email.trim(),
        'firebase_instance_id': firebaseInstanceId,
        'device_name': deviceName,
        'device_model': deviceModel,
        'os_version': osVersion,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if ((data['code'] ?? '').toString() != '200') {
      throw Exception(
        (data['message'] ?? 'Device registration failed').toString(),
      );
    }
  }

  Future<OtpSendResult> sendOtp({
    required String mobile,
    required String name,
    required String email,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'send_login_otp.php',
      data: <String, dynamic>{
        'mobile': mobile.trim(),
        'name': name.trim(),
        'email': email.trim(),
      },
    );
    return _parseOtpSendResponse(response.data as Map<String, dynamic>);
  }

  Future<OtpSendResult> forgotOtp({required String mobile}) async {
    final response = await _apiClient.dio.post<dynamic>(
      'forgot_password_otp.php',
      data: <String, dynamic>{'mobile': mobile.trim()},
    );
    return _parseOtpSendResponse(response.data as Map<String, dynamic>);
  }

  OtpSendResult _parseOtpSendResponse(Map<String, dynamic> data) {
    if (data['error'] == true) {
      throw Exception((data['message'] ?? 'OTP request failed').toString());
    }

    final code = (data['code'] ?? '').toString();
    final status = (data['status'] ?? '').toString().toLowerCase();
    final isSuccess = code == '200' || status == 'success';

    if (!isSuccess) {
      throw Exception((data['message'] ?? 'OTP request failed').toString());
    }

    final otp = OtpUtils.parseFromResponse(data) ?? '';
    final message = (data['message'] ?? data['result'] ?? 'OTP sent successfully')
        .toString();

    return OtpSendResult(otp: otp, message: message);
  }

  Future<String> forgotUpdate({
    required String mobile,
    required String password,
    required String otp,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'forgot_password_update.php',
      data: <String, dynamic>{
        'mobile': mobile.trim(),
        'password': password,
        'otp': otp.trim(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    if ((data['code'] ?? '').toString() != '200') {
      throw Exception(
        (data['message'] ?? 'Failed to update password').toString(),
      );
    }
    return (data['result'] ?? data['message'] ?? 'Password updated').toString();
  }

  Future<void> logout({
    required String customerId,
    required String token,
  }) async {
    final response = await _apiClient.dio.post<dynamic>(
      'logout.php',
      data: <String, dynamic>{
        'customer_id': customerId,
        'token': token,
      },
    );
    final data = response.data as Map<String, dynamic>;
    if ((data['code'] ?? '').toString() != '200') {
      throw Exception((data['message'] ?? 'Logout failed').toString());
    }
  }
}
