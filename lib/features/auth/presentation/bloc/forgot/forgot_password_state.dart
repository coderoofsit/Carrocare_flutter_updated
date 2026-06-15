part of 'forgot_password_bloc.dart';

enum ForgotStatus { initial, loading, otpSent, otpVerified, success, failure }

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.serverOtp = '',
    this.showOtpField = false,
    this.showPasswordFields = false,
    this.otpButtonText = 'Send OTP',
    this.submitButtonText = 'Verify OTP',
  });

  final ForgotStatus status;
  final String? errorMessage;
  final String? successMessage;
  final String serverOtp;
  final bool showOtpField;
  final bool showPasswordFields;
  final String otpButtonText;
  final String submitButtonText;

  ForgotPasswordState copyWith({
    ForgotStatus? status,
    String? errorMessage,
    String? successMessage,
    String? serverOtp,
    bool? showOtpField,
    bool? showPasswordFields,
    String? otpButtonText,
    String? submitButtonText,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage ?? this.successMessage,
      serverOtp: serverOtp ?? this.serverOtp,
      showOtpField: showOtpField ?? this.showOtpField,
      showPasswordFields: showPasswordFields ?? this.showPasswordFields,
      otpButtonText: otpButtonText ?? this.otpButtonText,
      submitButtonText: submitButtonText ?? this.submitButtonText,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    errorMessage,
    successMessage,
    serverOtp,
    showOtpField,
    showPasswordFields,
    otpButtonText,
    submitButtonText,
  ];
}
