import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/utils/profile_prefs_sync.dart';
import 'package:carrocare_flutter/core/utils/session_debug.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/signup/signup_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/widgets/auth_fields.dart';
import 'package:carrocare_flutter/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
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

  void _sendOtp(SignupState state) {
    if (_otpActionInFlight || state.status == SignupStatus.loading) return;
    setState(() => _otpActionInFlight = true);
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<SignupBloc>().add(
      SignupSendOtpPressed(
        name: _nameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
      ),
    );
  }

  void _submitSignup(SignupState state) {
    if (_otpActionInFlight || state.status == SignupStatus.loading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<SignupBloc>().add(
      SignupSubmitPressed(
        name: _nameController.text,
        email: _emailController.text,
        mobile: _mobileController.text,
        otp: _otpController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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

    return BlocListener<SignupBloc, SignupState>(
      listenWhen: (SignupState previous, SignupState current) =>
          previous.status != current.status ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage,
      listener: (context, state) async {
        if (state.status == SignupStatus.otpSent &&
            state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
          _otpController.clear();
          _releaseOtpActionLock();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
        if (state.status == SignupStatus.otpVerified) {
          _releaseOtpActionLock();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP verified. Please set your password.'),
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
        if (state.status == SignupStatus.success) {
          await _saveUserSession(
            userName: state.userName ?? _nameController.text,
            userMobile: state.userMobile ?? _mobileController.text,
            userToken: state.userToken ?? '',
            customerId: state.customerId ?? '',
            accessToken: state.accessToken ?? '',
            refreshToken: state.refreshToken ?? '',
            email: _emailController.text.trim(),
          );
          if (!context.mounted) return;
          context.go('/home');
        }
      },
      child: AuthScaffold(
        title: 'Sign Up',
        subtitle: 'Welcome to the Carro Care !!',
        onBack: () => context.go('/login'),
        child: BlocBuilder<SignupBloc, SignupState>(
          builder: (context, state) {
            return Column(
              children: <Widget>[
                AuthField(
                  controller: _nameController,
                  hint: 'Username',
                  assetIcon: 'assets/images/user.png',
                ),
                const SizedBox(height: 4),
                AuthField(
                  controller: _emailController,
                  hint: 'Email address',
                  assetIcon: 'assets/images/email.png',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 4),
                AuthField(
                  controller: _mobileController,
                  hint: 'Mobile No',
                  assetIcon: 'assets/images/phone.png',
                  keyboardType: TextInputType.phone,
                ),
                if (state.showOtp) ...<Widget>[
                  const SizedBox(height: 4),
                  AuthField(
                    controller: _otpController,
                    hint: 'OTP',
                    assetIcon: 'assets/images/phone.png',
                    keyboardType: TextInputType.number,
                  ),
                ],
                if (state.showPassword) ...<Widget>[
                  const SizedBox(height: 4),
                  AuthField(
                    controller: _passwordController,
                    hint: 'Password',
                    assetIcon: 'assets/images/password.png',
                    obscure: true,
                  ),
                  const SizedBox(height: 4),
                  AuthField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    assetIcon: 'assets/images/password.png',
                    obscure: true,
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
                        onPressed: state.status == SignupStatus.loading ||
                                _otpActionInFlight
                            ? null
                            : () => _sendOtp(state),
                        child: Text(state.showOtp ? 'RESEND OTP' : 'SEND OTP'),
                      ),
                    ),
                  ],
                ),
                if (state.showOtp) ...<Widget>[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state.status == SignupStatus.loading ||
                              _otpActionInFlight
                          ? null
                          : () => _submitSignup(state),
                      child: Text(
                        state.showPassword ? 'REGISTER' : 'VERIFY OTP',
                      ),
                    ),
                  ),
                ],
                SizedBox(height: compact ? 18 : 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Already Have An Account ?  ',
                      style: TextStyle(fontSize: compact ? 16 : 18),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: compact ? 16 : 18,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveUserSession({
    required String userName,
    required String userMobile,
    required String userToken,
    required String customerId,
    required String accessToken,
    required String refreshToken,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', userName);
    await prefs.setString('name', userName);
    await prefs.setString('usermobile', userMobile);
    await prefs.setString('mobile', userMobile);
    await prefs.setString('email', email);
    await prefs.setString('token', userToken);
    await prefs.setString('customer_id', customerId);
    if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
      await sl<AuthTokenService>().saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
    await syncProfileFromServer(token: userToken, customerId: customerId);
    await SessionDebug.logCustomerId(tag: 'Signup');
  }
}
