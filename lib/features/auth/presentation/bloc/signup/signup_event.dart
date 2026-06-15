part of 'signup_bloc.dart';

sealed class SignupEvent extends Equatable {
  const SignupEvent();

  @override
  List<Object?> get props => <Object?>[];
}

class SignupSendOtpPressed extends SignupEvent {
  const SignupSendOtpPressed({
    required this.name,
    required this.email,
    required this.mobile,
  });

  final String name;
  final String email;
  final String mobile;

  @override
  List<Object?> get props => <Object?>[name, email, mobile];
}

class SignupSubmitPressed extends SignupEvent {
  const SignupSubmitPressed({
    required this.name,
    required this.email,
    required this.mobile,
    required this.otp,
    required this.password,
    required this.confirmPassword,
  });

  final String name;
  final String email;
  final String mobile;
  final String otp;
  final String password;
  final String confirmPassword;

  @override
  List<Object?> get props => <Object?>[
    name,
    email,
    mobile,
    otp,
    password,
    confirmPassword,
  ];
}
