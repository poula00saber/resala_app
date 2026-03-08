import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../themes/app_theme.dart';

/// A whale-shaped loading indicator that replaces CircularProgressIndicator
/// throughout the app. Uses a whale icon with a smooth bobbing + rotating animation.
class WhaleLoading extends StatefulWidget {
  final double size;
  final Color? color;

  const WhaleLoading({super.key, this.size = 48, this.color});

  @override
  State<WhaleLoading> createState() => _WhaleLoadingState();
}

class _WhaleLoadingState extends State<WhaleLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Smooth sinusoidal bobbing
        final bobOffset = math.sin(_controller.value * 2 * math.pi) * 8;
        // Gentle tilt
        final tilt = math.sin(_controller.value * 2 * math.pi) * 0.15;
        // Scale pulse
        final scale = 1.0 + math.sin(_controller.value * 2 * math.pi) * 0.08;

        return Transform.translate(
          offset: Offset(0, bobOffset),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _WhalePainter(color: color),
      ),
    );
  }
}

class _WhalePainter extends CustomPainter {
  final Color color;
  _WhalePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Whale body (ellipse)
    final bodyRect = Rect.fromCenter(
      center: Offset(w * 0.45, h * 0.5),
      width: w * 0.7,
      height: h * 0.45,
    );
    canvas.drawOval(bodyRect, paint);

    // Whale tail
    final tailPath = Path()
      ..moveTo(w * 0.78, h * 0.45)
      ..quadraticBezierTo(w * 0.92, h * 0.25, w, h * 0.3)
      ..quadraticBezierTo(w * 0.92, h * 0.45, w * 0.85, h * 0.5)
      ..quadraticBezierTo(w * 0.92, h * 0.55, w, h * 0.7)
      ..quadraticBezierTo(w * 0.92, h * 0.75, w * 0.78, h * 0.55)
      ..close();
    canvas.drawPath(tailPath, paint);

    // Whale belly (lighter)
    final bellyPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final bellyRect = Rect.fromCenter(
      center: Offset(w * 0.4, h * 0.58),
      width: w * 0.5,
      height: h * 0.2,
    );
    canvas.drawOval(bellyRect, bellyPaint);

    // Eye
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.22, h * 0.43), w * 0.04, eyePaint);
    final pupilPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.22, h * 0.43), w * 0.02, pupilPaint);

    // Water spout
    final spoutPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final spoutPath = Path()
      ..moveTo(w * 0.35, h * 0.28)
      ..quadraticBezierTo(w * 0.32, h * 0.12, w * 0.28, h * 0.05)
      ..moveTo(w * 0.35, h * 0.28)
      ..quadraticBezierTo(w * 0.38, h * 0.12, w * 0.42, h * 0.05);
    canvas.drawPath(spoutPath, spoutPaint);

    // Fin
    final finPath = Path()
      ..moveTo(w * 0.45, h * 0.38)
      ..quadraticBezierTo(w * 0.48, h * 0.22, w * 0.55, h * 0.28)
      ..quadraticBezierTo(w * 0.52, h * 0.36, w * 0.5, h * 0.42)
      ..close();
    canvas.drawPath(finPath, paint..color = color.withOpacity(0.7));
  }

  @override
  bool shouldRepaint(covariant _WhalePainter old) => old.color != color;
}
