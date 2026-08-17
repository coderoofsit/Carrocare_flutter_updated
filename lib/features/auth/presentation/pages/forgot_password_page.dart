import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/forgot/forgot_password_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/widgets/auth_fields.dart';
import 'package:carrocare_flutter/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _otpActionInFlight = false;

  void _releaseOtpActionLock() {
    if (mounted) {
      setState(() => _otpActionInFlight = false);
    } else {
      _otpActionInFlight = false;
    }
  }

  void _sendOtp(ForgotPasswordState state) {
    if (_otpActionInFlight || state.status == ForgotStatus.loading) return;
    setState(() => _otpActionInFlight = true);
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<ForgotPasswordBloc>().add(
      ForgotSendOtpPressed(mobile: _mobileController.text),
    );
  }

  void _submitForgot(ForgotPasswordState state) {
    if (_otpActionInFlight || state.status == ForgotStatus.loading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<ForgotPasswordBloc>().add(
      ForgotSubmitPressed(
        mobile: _mobileController.text,
        otp: _otpController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 380;
    return BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
      listenWhen: (ForgotPasswordState previous, ForgotPasswordState current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.status == ForgotStatus.otpSent &&
            state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
          _otpController.clear();
          _releaseOtpActionLock();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
        if (state.status == ForgotStatus.otpVerified) {
          _releaseOtpActionLock();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified. Please set your new password.'),
            ),
          );
          return;
        }
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          _releaseOtpActionLock();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.status == ForgotStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage ?? 'Password updated')),
          );
          context.go('/login');
        }
      },
      child: AuthScaffold(
        title: 'Forgot Password ?',
        subtitle: 'Welcome to the Carro Care !!',
        onBack: () => context.go('/login'),
        bodyBackgroundColor: const Color(0xFFEDEFF1),
        child: BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
          builder: (context, state) {
            return Column(
              children: <Widget>[
                AuthField(
                  controller: _mobileController,
                  hint: 'Mobile No.',
                  assetIcon: 'assets/images/phone.png',
                  keyboardType: TextInputType.phone,
                  borderColor: const Color(0xFF8F8F8F),
                  borderRadius: 7,
                ),
                if (state.showOtpField) ...<Widget>[
                  const SizedBox(height: 10),
                  AuthField(
                    controller: _otpController,
                    hint: 'OTP',
                    assetIcon: 'assets/images/phone.png',
                    keyboardType: TextInputType.number,
                    borderColor: const Color(0xFF8F8F8F),
                    borderRadius: 7,
                  ),
                ],
                if (state.showPasswordFields) ...<Widget>[
                  const SizedBox(height: 10),
                  AuthField(
                    controller: _passwordController,
                    hint: 'New Password',
                    assetIcon: 'assets/images/password.png',
                    obscure: true,
                    borderColor: const Color(0xFF8F8F8F),
                    borderRadius: 7,
                  ),
                  const SizedBox(height: 10),
                  AuthField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm New Password',
                    assetIcon: 'assets/images/password.png',
                    obscure: true,
                    borderColor: const Color(0xFF8F8F8F),
                    borderRadius: 7,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('BACK'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.status == ForgotStatus.loading ||
                                _otpActionInFlight
                            ? null
                            : () => _sendOtp(state),
                        child: state.status == ForgotStatus.loading ||
                                _otpActionInFlight
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(state.otpButtonText.toUpperCase()),
                      ),
                    ),
                  ],
                ),
                if (state.showOtpField) ...<Widget>[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.status == ForgotStatus.loading ||
                              _otpActionInFlight
                          ? null
                          : () => _submitForgot(state),
                      child: state.status == ForgotStatus.loading ||
                              _otpActionInFlight
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(state.submitButtonText.toUpperCase()),
                    ),
                  ),
                ],
                SizedBox(height: compact ? 18 : 24),
                Text(
                  ' ',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: compact ? 16 : 18,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
