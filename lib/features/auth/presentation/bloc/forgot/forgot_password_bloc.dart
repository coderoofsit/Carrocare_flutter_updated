import 'package:carrocare_flutter/core/utils/otp_utils.dart';
import 'package:carrocare_flutter/features/auth/domain/usecases/auth_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc(this._forgotOtpUseCase, this._forgotUpdateUseCase)
    : super(const ForgotPasswordState()) {
    on<ForgotSendOtpPressed>(_onSendOtpPressed);
    on<ForgotSubmitPressed>(_onSubmitPressed);
  }

  final ForgotOtpUseCase _forgotOtpUseCase;
  final ForgotUpdateUseCase _forgotUpdateUseCase;

  Future<void> _onSendOtpPressed(
    ForgotSendOtpPressed event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (event.mobile.isEmpty) {
      emit(state.copyWith(errorMessage: 'Enter all the details'));
      return;
    }
    if (event.mobile.length != 10) {
      emit(state.copyWith(errorMessage: 'Enter valid mobile number'));
      return;
    }
    emit(state.copyWith(status: ForgotStatus.loading, errorMessage: null));
    try {
      final result = await _forgotOtpUseCase(mobile: event.mobile);
      emit(
        state.copyWith(
          status: ForgotStatus.otpSent,
          serverOtp: result.otp,
          showOtpField: true,
          showPasswordFields: false,
          otpButtonText: 'Resend OTP',
          submitButtonText: 'Verify OTP',
          successMessage: result.message,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ForgotStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> _onSubmitPressed(
    ForgotSubmitPressed event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (state.submitButtonText == 'Verify OTP') {
      if (event.otp.trim().isEmpty) {
        emit(state.copyWith(errorMessage: 'Enter all the details'));
        return;
      }
      if (!OtpUtils.verify(event.otp, state.serverOtp)) {
        emit(state.copyWith(errorMessage: 'Enter valid OTP'));
        return;
      }
      emit(
        state.copyWith(
          showPasswordFields: true,
          submitButtonText: 'Submit',
          status: ForgotStatus.otpVerified,
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
    emit(state.copyWith(status: ForgotStatus.loading, errorMessage: null));
    try {
      final result = await _forgotUpdateUseCase(
        mobile: event.mobile,
        password: event.password,
        otp: event.otp,
      );
      emit(
        state.copyWith(status: ForgotStatus.success, successMessage: result),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ForgotStatus.failure,
          errorMessage: 'Timeout.Try after sometime',
        ),
      );
    }
  }
}
