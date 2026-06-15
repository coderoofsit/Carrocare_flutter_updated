import 'package:carrocare_flutter/core/utils/otp_utils.dart';
import 'package:carrocare_flutter/core/utils/validators.dart';
import 'package:carrocare_flutter/features/auth/domain/usecases/auth_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  SignupBloc(this._sendOtpUseCase, this._registerUseCase)
    : super(const SignupState()) {
    on<SignupSendOtpPressed>(_onSendOtp);
    on<SignupSubmitPressed>(_onSubmit);
  }

  final SendOtpUseCase _sendOtpUseCase;
  final RegisterUseCase _registerUseCase;

  Future<void> _onSendOtp(
    SignupSendOtpPressed event,
    Emitter<SignupState> emit,
  ) async {
    if (event.name.isEmpty || event.email.isEmpty || event.mobile.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter all the details'));
      return;
    }
    if (event.mobile.length != 10) {
      emit(state.copyWith(errorMessage: 'Enter valid mobile number'));
      return;
    }
    if (!Validators.isValidEmail(event.email)) {
      emit(state.copyWith(errorMessage: 'Enter valid Email ID'));
      return;
    }
    emit(state.copyWith(status: SignupStatus.loading, errorMessage: null));
    try {
      final result = await _sendOtpUseCase(
        mobile: event.mobile,
        name: event.name,
        email: event.email,
      );
      emit(
        state.copyWith(
          status: SignupStatus.otpSent,
          serverOtp: result.otp,
          showOtp: true,
          showPassword: false,
          successMessage: result.message,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SignupStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSubmit(
    SignupSubmitPressed event,
    Emitter<SignupState> emit,
  ) async {
    if (!state.showPassword) {
      if (!OtpUtils.verify(event.otp, state.serverOtp)) {
        emit(state.copyWith(errorMessage: 'Enter valid OTP'));
        return;
      }
      emit(
        state.copyWith(
          showPassword: true,
          status: SignupStatus.otpVerified,
          errorMessage: null,
        ),
      );
      return;
    }
    if (event.password.isEmpty || event.confirmPassword.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter all the details'));
      return;
    }
    if (event.password != event.confirmPassword) {
      emit(state.copyWith(errorMessage: 'Password are not matched'));
      return;
    }
    if (event.otp.trim().isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter all the details'));
      return;
    }
    emit(state.copyWith(status: SignupStatus.loading, errorMessage: null));
    try {
      final response = await _registerUseCase(
        mobile: event.mobile,
        password: event.password,
        name: event.name,
        email: event.email,
        otp: event.otp,
        deviceId: 'flutter-device-id',
        deviceName: 'flutter',
        deviceModel: 'flutter',
        osVersion: 'flutter',
      );
      if (response.code == '200') {
        emit(
          state.copyWith(
            status: SignupStatus.success,
            userName: response.name,
            userMobile: response.mobile,
            userToken: response.token,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            customerId: response.customerId,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: SignupStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: SignupStatus.failure,
          errorMessage: 'Timeout.Try after sometime',
        ),
      );
    }
  }
}
