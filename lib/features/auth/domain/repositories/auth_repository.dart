import 'package:carrocare_flutter/features/auth/data/models/login_response_model.dart';
import 'package:carrocare_flutter/features/auth/data/models/otp_send_result.dart';

abstract class AuthRepository {
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  });

  Future<OtpSendResult> sendOtp({
    required String mobile,
    required String name,
    required String email,
  });

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
  });

  Future<OtpSendResult> sendForgotOtp({required String mobile});

  Future<String> updateForgotPassword({
    required String mobile,
    required String password,
    required String otp,
  });
}
