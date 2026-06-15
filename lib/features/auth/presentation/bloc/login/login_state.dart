part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.errorMessage,
    this.userName,
    this.userMobile,
    this.userEmail,
    this.userToken,
    this.accessToken,
    this.refreshToken,
    this.customerId,
  });

  final LoginStatus status;
  final String? errorMessage;
  final String? userName;
  final String? userMobile;
  final String? userEmail;
  final String? userToken;
  final String? accessToken;
  final String? refreshToken;
  final String? customerId;

  LoginState copyWith({
    LoginStatus? status,
    String? errorMessage,
    String? userName,
    String? userMobile,
    String? userEmail,
    String? userToken,
    String? accessToken,
    String? refreshToken,
    String? customerId,
  }) {
    return LoginState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      userName: userName ?? this.userName,
      userMobile: userMobile ?? this.userMobile,
      userEmail: userEmail ?? this.userEmail,
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
    userName,
    userMobile,
    userEmail,
    userToken,
    accessToken,
    refreshToken,
    customerId,
  ];
}
