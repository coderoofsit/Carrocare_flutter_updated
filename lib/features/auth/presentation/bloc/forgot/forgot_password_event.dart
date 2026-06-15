part of 'forgot_password_bloc.dart';

sealed class ForgotPasswordEvent extends Equatable {
  const ForgotPasswordEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class ForgotSendOtpPressed extends ForgotPasswordEvent {
  const ForgotSendOtpPressed({required this.mobile});

  final String mobile;

  @override
  List<Object?> get props => <Object?>[mobile];
}

class ForgotSubmitPressed extends ForgotPasswordEvent {
  const ForgotSubmitPressed({
    required this.mobile,
    required this.otp,
    required this.password,
    required this.confirmPassword,
  });

  final String mobile;
  final String otp;
  final String password;
  final String confirmPassword;

  @override
  List<Object?> get props => <Object?>[mobile, otp, password, confirmPassword];
}
