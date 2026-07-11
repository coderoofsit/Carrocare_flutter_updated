import 'dart:math' as math;

import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:carrocare_flutter/core/theme/app_typography.dart';
import 'package:carrocare_flutter/core/widgets/carro_care_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Polished placeholder shown while Door Step Service is not yet live.
class DoorStepComingSoonPage extends StatefulWidget {
  const DoorStepComingSoonPage({super.key});

  @override
  State<DoorStepComingSoonPage> createState() => _DoorStepComingSoonPageState();
}

class _DoorStepComingSoonPageState extends State<DoorStepComingSoonPage>
    with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;
  late final AnimationController _entranceController;
  late final AnimationController _shimmerController;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _chipsFade;
  late final Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _bodyFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _chipsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 0.9, curve: Curves.easeOut),
    );
    _ctaFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _entranceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CarroCareScaffold(
      title: 'Door Step Service',
      onBack: () => context.pop(),
      appBarTransparent: true,
      showAppBarBorder: false,
      backgroundDecoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF5F5),
            Color(0xFFFFE8E8),
            Color(0xFFFFF8F8),
            AppColors.white,
          ],
          stops: <double>[0.0, 0.35, 0.7, 1.0],
        ),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[
                _orbitController,
                _floatController,
              ]),
              builder: (context, _) {
                return CustomPaint(
                  painter: _FloatingOrbsPainter(
                    orbit: _orbitController.value,
                    float: _floatController.value,
                  ),
                );
              },
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 640;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      SizedBox(height: compact ? 8 : 16),
                      Column(
                        children: <Widget>[
                          _HeroStage(
                            orbit: _orbitController,
                            pulse: _pulseController,
                            float: _floatController,
                            size: compact ? 180 : 220,
                          ),
                          SizedBox(height: compact ? 24 : 36),
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: Column(
                                children: <Widget>[
                                  _ShimmerBadge(
                                    controller: _shimmerController,
                                  ),
                                  const SizedBox(height: 14),
                                  _AnimatedComingSoonTitle(
                                    controller: _shimmerController,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeTransition(
                            opacity: _bodyFade,
                            child: SlideTransition(
                              position: _bodySlide,
                              child: Text(
                                'Professional car care, right at your doorstep.\n'
                                'We\'re putting the finishing polish on this experience.',
                                textAlign: TextAlign.center,
                                style: AppTypography.dmSans(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: compact ? 18 : 28),
                          FadeTransition(
                            opacity: _chipsFade,
                            child: const _FeatureRow(),
                          ),
                        ],
                      ),
                      FadeTransition(
                        opacity: _ctaFade,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: compact ? 20 : 28,
                            bottom: 24,
                          ),
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: () => context.pop(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Back to Home',
                                    style: AppTypography.quicksand(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Stay tuned — launching soon',
                                style: AppTypography.dmSans(
                                  fontSize: 12,
                                  color: AppColors.grey500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroStage extends StatelessWidget {
  const _HeroStage({
    required this.orbit,
    required this.pulse,
    required this.float,
    this.size = 220,
  });

  final AnimationController orbit;
  final AnimationController pulse;
  final AnimationController float;
  final double size;

  @override
  Widget build(BuildContext context) {
    final coreSize = size * 0.536;
    final orbitRadius = size * 0.4;

    return SizedBox(
      height: size,
      width: size,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[orbit, pulse, float]),
        builder: (context, _) {
          final pulseT = Curves.easeInOut.transform(pulse.value);
          final floatY = math.sin(float.value * math.pi) * 8;

          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              for (var i = 0; i < 3; i++)
                Transform.scale(
                  scale: 0.72 + (i * 0.16) + (pulseT * 0.06),
                  child: Container(
                    width: size * 0.91,
                    height: size * 0.91,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: 0.18 - (i * 0.045),
                        ),
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ..._buildOrbitingIcons(orbit.value, orbitRadius),
              Transform.translate(
                offset: Offset(0, floatY),
                child: Container(
                  width: coreSize,
                  height: coreSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        AppColors.primary.withValues(alpha: 0.95),
                        AppColors.primaryDark,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: 0.28 + (pulseT * 0.18),
                        ),
                        blurRadius: 28 + (pulseT * 12),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.home_work_rounded,
                    size: coreSize * 0.44,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildOrbitingIcons(double t, double radius) {
    const icons = <IconData>[
      Icons.local_car_wash_rounded,
      Icons.water_drop_rounded,
      Icons.auto_awesome_rounded,
      Icons.directions_car_filled_rounded,
    ];
    const labels = <Color>[
      Color(0xFFFF6B6B),
      Color(0xFFFF8E8E),
      Color(0xFFEE3131),
      Color(0xFFFF5A5A),
    ];

    final iconBox = size * 0.19;

    return List<Widget>.generate(icons.length, (i) {
      final angle = (t * 2 * math.pi) + (i * (math.pi / 2));
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius * 0.78;

      return Transform.translate(
        offset: Offset(x, y),
        child: Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.primaryTintStrong),
          ),
          child: Icon(icons[i], size: iconBox * 0.48, color: labels[i]),
        ),
      );
    });
  }
}

class _ShimmerBadge extends StatelessWidget {
  const _ShimmerBadge({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (controller.value * 2), 0),
              end: Alignment(1.0 + (controller.value * 2), 0),
              colors: const <Color>[
                AppColors.primaryTintStrong,
                Color(0xFFFFD6D6),
                AppColors.primaryTintStrong,
              ],
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: AppColors.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'Something exciting is on the way',
                style: AppTypography.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedComingSoonTitle extends StatelessWidget {
  const _AnimatedComingSoonTitle({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + (controller.value * 2.4), 0),
              end: Alignment(-0.2 + (controller.value * 2.4), 0),
              colors: const <Color>[
                AppColors.grey900,
                AppColors.primary,
                AppColors.grey900,
              ],
              stops: const <double>[0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: Text(
            'Coming Soon',
            textAlign: TextAlign.center,
            style: AppTypography.quicksand(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              height: 1.1,
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.door_front_door_outlined, 'At your door'),
      (Icons.verified_outlined, 'Expert care'),
      (Icons.bolt_rounded, 'On demand'),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey200),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(item.$1, color: AppColors.primary, size: 22),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        textAlign: TextAlign.center,
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FloatingOrbsPainter extends CustomPainter {
  _FloatingOrbsPainter({required this.orbit, required this.float});

  final double orbit;
  final double float;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    void drawOrb(Offset c, double r, Color color) {
      paint.color = color;
      canvas.drawCircle(c, r, paint);
    }

    final t = orbit * 2 * math.pi;
    final f = float * math.pi;

    drawOrb(
      Offset(
        size.width * 0.12 + math.cos(t) * 12,
        size.height * 0.18 + math.sin(f) * 10,
      ),
      38,
      AppColors.primary.withValues(alpha: 0.07),
    );
    drawOrb(
      Offset(
        size.width * 0.88 + math.sin(t) * 14,
        size.height * 0.28 + math.cos(f) * 12,
      ),
      52,
      AppColors.primaryLight.withValues(alpha: 0.08),
    );
    drawOrb(
      Offset(
        size.width * 0.78 + math.cos(t * 0.7) * 10,
        size.height * 0.72 + math.sin(f * 1.2) * 14,
      ),
      44,
      AppColors.primary.withValues(alpha: 0.06),
    );
    drawOrb(
      Offset(
        size.width * 0.18 + math.sin(t * 1.1) * 8,
        size.height * 0.78 + math.cos(f) * 10,
      ),
      28,
      const Color(0xFFFFB4B4).withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _FloatingOrbsPainter oldDelegate) {
    return oldDelegate.orbit != orbit || oldDelegate.float != float;
  }
}
