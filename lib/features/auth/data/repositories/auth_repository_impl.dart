import 'package:carrocare_flutter/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:carrocare_flutter/features/auth/data/models/login_response_model.dart';
import 'package:carrocare_flutter/features/auth/data/models/otp_send_result.dart';
import 'package:carrocare_flutter/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) {
    return _remote.login(email: email, password: password);
  }

  @override
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
  }) {
    return _remote.register(
      mobile: mobile,
      password: password,
      name: name,
      email: email,
      otp: otp,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceModel: deviceModel,
      osVersion: osVersion,
    );
  }

  @override
  Future<OtpSendResult> sendOtp({
    required String mobile,
    required String name,
    required String email,
  }) {
    return _remote.sendOtp(mobile: mobile, name: name, email: email);
  }

  @override
  Future<OtpSendResult> sendForgotOtp({required String mobile}) {
    return _remote.forgotOtp(mobile: mobile);
  }

  @override
  Future<String> updateForgotPassword({
    required String mobile,
    required String password,
    required String otp,
  }) {
    return _remote.forgotUpdate(mobile: mobile, password: password, otp: otp);
  }
}
