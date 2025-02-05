import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/gem_theme.dart';

enum GemButtonStyle {
  primary,
  secondary
}

class GemButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Color gemColor;
  final bool isAnimated;
  final GemButtonStyle style;

  const GemButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.gemColor = emerald,
    this.isAnimated = false,
    this.style = GemButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(emeraldCut),
        gradient: style == GemButtonStyle.primary
            ? LinearGradient(
                colors: [
                  gemColor,
                  gemColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: style == GemButtonStyle.primary
              ? gemColor.withOpacity(0.3)
              : gemColor,
          width: style == GemButtonStyle.primary ? 1 : 2,
        ),
      ),
      child: Material(
        color: style == GemButtonStyle.primary
            ? Colors.transparent
            : deepCave,
        borderRadius: BorderRadius.circular(emeraldCut),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(emeraldCut),
          splashColor: gemColor.withOpacity(0.3),
          highlightColor: gemColor.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
            child: Text(
              text,
              style: gemText.copyWith(
                color: style == GemButtonStyle.primary
                    ? Colors.white
                    : gemColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _SparkleEffectPainter extends CustomPainter {
  final Color color;
  final double progress;
  final List<Offset> sparklePoints;
  final bool isHovered;

  _SparkleEffectPainter({
    required this.color,
    required this.progress,
    required this.sparklePoints,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (var point in sparklePoints) {
      final sparkleSize = isHovered ? 4.0 : 2.0;
      final x = size.width * (0.5 + point.dx * 0.5);
      final y = size.height * (0.5 + point.dy * 0.5);
      
      // Calculate sparkle opacity based on progress
      final opacity = (math.sin(progress * math.pi * 2 + 
                     point.dx * math.pi) * 0.5 + 0.5) * 
                     (isHovered ? 0.8 : 0.4);
      
      paint.color = color.withOpacity(opacity);
      
      canvas.drawCircle(
        Offset(x, y),
        sparkleSize * (math.sin(progress * math.pi * 2 + point.dy * math.pi) * 0.3 + 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkleEffectPainter oldDelegate) {
    return progress != oldDelegate.progress || 
           isHovered != oldDelegate.isHovered;
  }
} 