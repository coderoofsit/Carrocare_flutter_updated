import 'package:flutter/material.dart';

class AnimatedGradientBadge extends StatefulWidget {
  const AnimatedGradientBadge({
    super.key,
    required this.label,
    this.vibrant = true,
  });

  final String label;
  final bool vibrant;

  @override
  State<AnimatedGradientBadge> createState() => _AnimatedGradientBadgeState();
}

class _AnimatedGradientBadgeState extends State<AnimatedGradientBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _colors => widget.vibrant
      ? const <Color>[
          Color(0xFFFF8A8A),
          Color(0xFFFF4D4D),
          Color(0xFFFFB3B3),
          Color(0xFFFF6B6B),
          Color(0xFFFF8A8A),
        ]
      : const <Color>[
          Color(0xFFB8C6DB),
          Color(0xFF8E9EAB),
          Color(0xFFD7DEE8),
          Color(0xFFA8B8C8),
          Color(0xFFB8C6DB),
        ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double shift = _controller.value * 2;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: (widget.vibrant
                        ? const Color(0xFFFF4D4D)
                        : const Color(0xFF8E9EAB))
                    .withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment(-1 + shift, -0.6),
              end: Alignment(1 + shift, 0.6),
              colors: _colors,
              stops: const <double>[0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.vibrant ? Colors.white : const Color(0xFF2D3748),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            shadows: widget.vibrant
                ? <Shadow>[
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
