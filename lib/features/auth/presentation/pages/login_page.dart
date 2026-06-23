import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/network/auth_token_service.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/utils/profile_prefs_sync.dart';
import 'package:carrocare_flutter/core/utils/session_debug.dart';
import 'package:carrocare_flutter/features/auth/presentation/bloc/login/login_bloc.dart';
import 'package:carrocare_flutter/features/auth/presentation/widgets/auth_fields.dart';
import 'package:carrocare_flutter/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool compact = size.width < 380;

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.status == LoginStatus.success) {
          await _saveUserSession(
            userName: state.userName ?? '',
            userMobile: state.userMobile ?? '',
            userToken: state.userToken ?? '',
            customerId: state.customerId ?? '',
            accessToken: state.accessToken ?? '',
            refreshToken: state.refreshToken ?? '',
            email: state.userEmail ?? _emailController.text.trim(),
          );
          if (!context.mounted) return;
          context.go('/home');
        }
      },
      child: AuthScaffold(
        title: 'Sign In',
        subtitle: 'Welcome to the Carro Care !!',
        showAppBar: false,
        child: Column(
          children: <Widget>[
            AuthField(
              controller: _emailController,
              hint: 'Email address',
              assetIcon: 'assets/images/email.png',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 4),
            AuthField(
              controller: _passwordController,
              hint: 'Password',
              assetIcon: 'assets/images/password.png',
              obscure: _obscure,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Image.asset(
                  _obscure
                      ? 'assets/images/ic_invisible.png'
                      : 'assets/images/ic_visible.png',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () => context.go('/forgot-password'),
                  child: Text(
                    'Forgot password ?',
                    style: TextStyle(fontSize: compact ? 16 : 18),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 22 : 30),
            SizedBox(
              width: double.infinity,
              child: BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return ElevatedButton(
                    onPressed: state.status == LoginStatus.loading
                        ? null
                        : () {
                            context.read<LoginBloc>().add(
                              LoginSubmitted(
                                email: _emailController.text,
                                password: _passwordController.text,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: state.status == LoginStatus.loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('LOGIN'),
                  );
                },
              ),
            ),
            SizedBox(height: compact ? 20 : 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Create An Account  ',
                  style: TextStyle(fontSize: compact ? 16 : 18),
                ),
                GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: Text(
                    'Sign Up',
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
    String email = '',
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
    await SessionDebug.logCustomerId(tag: 'Login');
  }
}
