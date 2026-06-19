import 'package:carrocare_flutter/core/di/injection.dart';
import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/remote_image_with_fallback.dart';
import 'package:carrocare_flutter/features/mobile_assets/data/repositories/mobile_assets_repository.dart';
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
  final PageController _controller = PageController();
  final MobileAssetsRepository _mobileAssets = sl<MobileAssetsRepository>();

  static const List<String> _fallbackAssets = <String>[
    'assets/images/intro_image1.jpg',
    'assets/images/intro_image2.jpg',
    'assets/images/intro_image3.jpg',
    'assets/images/intro_image4.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadMobileAssets();
  }

  Future<void> _loadMobileAssets() async {
    await _mobileAssets.ensureLoaded();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final slides = _mobileAssets.onboardingSlides(_fallbackAssets);
    final int slideCount = slides.isEmpty ? _fallbackAssets.length : slides.length;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final bool isLast = state.pageIndex >= slideCount - 1;
          return Stack(
            children: <Widget>[
              PageView.builder(
                controller: _controller,
                itemCount: slideCount,
                onPageChanged: (index) {
                  context.read<OnboardingBloc>().add(
                    OnboardingPageChanged(index),
                  );
                },
                itemBuilder: (_, index) {
                  final RemoteSlide slide = index < slides.length
                      ? slides[index]
                      : RemoteSlide(
                          fallbackAsset: _fallbackAssets[
                              index < _fallbackAssets.length
                                  ? index
                                  : _fallbackAssets.length - 1],
                        );
                  return RemoteImageWithFallback(
                    imageUrl: slide.imageUrl,
                    fallbackAsset: slide.fallbackAsset,
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
                    slideCount,
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
                              if (next < slideCount) {
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
