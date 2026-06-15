part of 'signup_bloc.dart';

enum SignupStatus { initial, loading, otpSent, otpVerified, success, failure }

class SignupState extends Equatable {
  const SignupState({
    this.status = SignupStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.serverOtp = '',
    this.showOtp = false,
    this.showPassword = false,
    this.userName,
    this.userMobile,
    this.userToken,
    this.accessToken,
    this.refreshToken,
    this.customerId,
  });

  final SignupStatus status;
  final String? errorMessage;
  final String? successMessage;
  final String serverOtp;
  final bool showOtp;
  final bool showPassword;
  final String? userName;
  final String? userMobile;
  final String? userToken;
  final String? accessToken;
  final String? refreshToken;
  final String? customerId;

  SignupState copyWith({
    SignupStatus? status,
    String? errorMessage,
    String? successMessage,
    String? serverOtp,
    bool? showOtp,
    bool? showPassword,
    String? userName,
    String? userMobile,
    String? userToken,
    String? accessToken,
    String? refreshToken,
    String? customerId,
  }) {
    return SignupState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      serverOtp: serverOtp ?? this.serverOtp,
      showOtp: showOtp ?? this.showOtp,
      showPassword: showPassword ?? this.showPassword,
      userName: userName ?? this.userName,
      userMobile: userMobile ?? this.userMobile,
      userToken: userToken ?? this.userToken,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      customerId: customerId ?? this.customerId,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    errorMessage,
    successMessage,
    serverOtp,
    showOtp,
    showPassword,
    userName,
    userMobile,
    userToken,
    accessToken,
    refreshToken,
    customerId,
  ];
}
