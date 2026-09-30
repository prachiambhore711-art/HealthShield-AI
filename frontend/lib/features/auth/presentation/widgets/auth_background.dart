import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Clean off-white canvas background
          Positioned.fill(
            child: Container(
              color: AppColors.background,
            ),
          ),
          // 2. Subtle soft mint floating accents (No pink)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.mint.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // 3. Custom geometric crosses/circuit line-art in the background
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(),
            ),
          ),
          // 4. Actual view content
          Positioned.fill(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.green.withOpacity(0.025)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw a decorative heartbeat-like line at the bottom
    final path = Path();
    path.moveTo(0, size.height * 0.85);
    path.lineTo(size.width * 0.1, size.height * 0.85);
    path.lineTo(size.width * 0.15, size.height * 0.82);
    path.lineTo(size.width * 0.2, size.height * 0.90);
    path.lineTo(size.width * 0.25, size.height * 0.80);
    path.lineTo(size.width * 0.3, size.height * 0.85);
    path.lineTo(size.width, size.height * 0.85);
    canvas.drawPath(path, paint);

    // Draw some subtle circular rings at the top left
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.15), 40, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.15), 80, paint);

    // Draw small crosses
    _drawCross(canvas, Offset(size.width * 0.8, size.height * 0.25), 8, paint);
    _drawCross(canvas, Offset(size.width * 0.15, size.height * 0.65), 10, paint);
    _drawCross(canvas, Offset(size.width * 0.85, size.height * 0.75), 12, paint);
  }

  void _drawCross(Canvas canvas, Offset center, double size, Paint paint) {
    canvas.drawLine(Offset(center.dx - size / 2, center.dy), Offset(center.dx + size / 2, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - size / 2), Offset(center.dx, center.dy + size / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
