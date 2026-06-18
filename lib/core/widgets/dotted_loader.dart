import 'package:carrocare_flutter/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum DottedLoaderSize { small, medium, large }

class DottedLoader extends StatefulWidget {
  const DottedLoader({
    super.key,
    this.size = DottedLoaderSize.medium,
    this.color = AppColors.primary,
  });

  final DottedLoaderSize size;
  final Color color;

  @override
  State<DottedLoader> createState() => _DottedLoaderState();
}

class _DottedLoaderState extends State<DottedLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double get _dotSize {
    switch (widget.size) {
      case DottedLoaderSize.small:
        return 6;
      case DottedLoaderSize.medium:
        return 8;
      case DottedLoaderSize.large:
        return 10;
    }
  }

  double get _gap {
    switch (widget.size) {
      case DottedLoaderSize.small:
        return 4;
      case DottedLoaderSize.medium:
        return 6;
      case DottedLoaderSize.large:
        return 8;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (index) {
            final delay = index * 0.2;
            final t = (_controller.value + delay) % 1.0;
            final scale = 0.6 + (0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0));
            final opacity = 0.4 + (0.6 * scale);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: _gap / 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: _dotSize,
                    height: _dotSize,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Full-screen or centered loading wrapper.
class CarroCareLoadingOverlay extends StatelessWidget {
  const CarroCareLoadingOverlay({
    super.key,
    this.size = DottedLoaderSize.large,
  });

  final DottedLoaderSize size;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: DottedLoader(size: DottedLoaderSize.large),
    );
  }
}
