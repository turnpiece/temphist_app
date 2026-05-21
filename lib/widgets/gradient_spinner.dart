import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

// Logo palette colours matching the web spinner gradient.
const _gradientColors = [
  Color(0xFF267CFA), // Royal Blue
  Color(0xFF80848E), // Slate Grey
  Color(0xFFFF1A1A), // Bright Red
  Color(0xFFA35C53), // Earthy Brick
  Color(0xFF267CFA), // seamless loop back to Blue
];

/// A spinning ring indicator.
///
/// With no [color] argument: sweeps through the app's logo palette gradient.
/// With a [color] argument: draws a solid monochrome ring in that colour.
class GradientSpinner extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const GradientSpinner({
    super.key,
    this.size = 64,
    this.strokeWidth = 5,
    this.color,
  });

  /// Gradient variant for data loading states.
  const GradientSpinner.data({super.key, this.size = 64, this.strokeWidth = 5})
      : color = null;

  /// Solid green variant for location detection states.
  const GradientSpinner.location({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
  }) : color = kButtonColour;

  @override
  State<GradientSpinner> createState() => _GradientSpinnerState();
}

class _GradientSpinnerState extends State<GradientSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
        builder: (context, _) {
          return CustomPaint(
            painter: _SpinnerPainter(
              progress: _controller.value,
              strokeWidth: widget.strokeWidth,
              solidColor: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color? solidColor;

  _SpinnerPainter({
    required this.progress,
    required this.strokeWidth,
    this.solidColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (solidColor != null) {
      paint.color = solidColor!;
      // Draw a ~270° arc that rotates.
      canvas.drawArc(
        rect,
        2 * pi * progress - pi / 2,
        3 * pi / 2,
        false,
        paint,
      );
    } else {
      // Full gradient ring: rotate the sweep gradient, draw a complete circle.
      paint.shader = SweepGradient(
        colors: _gradientColors,
        startAngle: 0,
        endAngle: 2 * pi,
        transform: GradientRotation(2 * pi * progress - pi / 2),
      ).createShader(rect);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.progress != progress ||
      old.strokeWidth != strokeWidth ||
      old.solidColor != solidColor;
}
