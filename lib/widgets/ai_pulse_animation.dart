import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AIPulseAnimation extends StatefulWidget {
  final double size;

  const AIPulseAnimation({
    super.key,
    this.size = 180,
  });

  @override
  State<AIPulseAnimation> createState() => _AIPulseAnimationState();
}

class _AIPulseAnimationState extends State<AIPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return CustomPaint(
            painter: _PulseOrbitPainter(progress: value),
            child: Center(
              child: Container(
                width: widget.size * 0.55,
                height: widget.size * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.burgundyGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.4 * math.sin(value * math.pi)),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: AppColors.gold,
                      size: 28,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PulseOrbitPainter extends CustomPainter {
  final double progress;

  _PulseOrbitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Outer pulse ring 1
    final ringPaint1 = Paint()
      ..color = AppColors.gold.withValues(alpha: (1.0 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius * (0.6 + progress * 0.4), ringPaint1);

    // Orbiting spark
    final angle = progress * 2 * math.pi;
    final sparkOffset = Offset(
      center.dx + radius * 0.85 * math.cos(angle),
      center.dy + radius * 0.85 * math.sin(angle),
    );

    final sparkPaint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    canvas.drawCircle(sparkOffset, 5, sparkPaint);
  }

  @override
  bool shouldRepaint(covariant _PulseOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
