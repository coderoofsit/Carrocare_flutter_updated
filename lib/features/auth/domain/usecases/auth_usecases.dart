import 'package:carrocare_flutter/features/auth/data/models/login_response_model.dart';
import 'package:carrocare_flutter/features/auth/data/models/otp_send_result.dart';
import 'package:carrocare_flutter/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<LoginResponseModel> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}

class SendOtpUseCase {
  const SendOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<OtpSendResult> call({
    required String mobile,
    required String name,
    required String email,
  }) {
    return _repository.sendOtp(mobile: mobile, name: name, email: email);
  }
}

class RegisterUseCase {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  Future<LoginResponseModel> call({
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
    return _repository.register(
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
}

class ForgotOtpUseCase {
  const ForgotOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<OtpSendResult> call({required String mobile}) {
    return _repository.sendForgotOtp(mobile: mobile);
  }
}

class ForgotUpdateUseCase {
  const ForgotUpdateUseCase(this._repository);
  final AuthRepository _repository;

  Future<String> call({
    required String mobile,
    required String password,
    required String otp,
  }) {
    return _repository.updateForgotPassword(
      mobile: mobile,
      password: password,
      otp: otp,
    );
  }
}
