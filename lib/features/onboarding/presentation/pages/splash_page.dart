import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const int maxStep = 4;
  final PageController _controller = PageController();

  final List<String> _images = <String>[
    'assets/images/intro_image1.jpg',
    'assets/images/intro_image2.jpg',
    'assets/images/intro_image3.jpg',
    'assets/images/intro_image4.jpg',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final bool isLast = state.pageIndex == _images.length - 1;
          return Stack(
            children: <Widget>[
              PageView.builder(
                controller: _controller,
                itemCount: _images.length,
                onPageChanged: (index) {
                  context.read<OnboardingBloc>().add(
                    OnboardingPageChanged(index),
                  );
                },
                itemBuilder: (_, index) {
                  return Image.asset(
                    _images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: media.height * 0.135,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(
                    maxStep,
                    (i) => Container(
                      width: 15,
                      height: 15,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == state.pageIndex
                            ? AppColors.primary
                            : AppColors.grey400,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 30,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    isLast
                        ? const SizedBox(width: 86)
                        : _CtaButton(
                            text: 'Skip',
                            icon: Icons.keyboard_double_arrow_right,
                            onPressed: () => context.go('/login'),
                          ),
                    isLast
                        ? _CtaButton(
                            text: 'login',
                            icon: Icons.login,
                            onPressed: () => context.go('/login'),
                          )
                        : _CtaButton(
                            text: 'Next',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              final next = state.pageIndex + 1;
                              if (next < maxStep) {
                                _controller.animateToPage(
                                  next,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(
        text,
        style: AppTypography.quicksand(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 7,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
    );
  }
}
