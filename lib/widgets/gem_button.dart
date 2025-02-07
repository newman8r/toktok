import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/gem_theme.dart';

enum GemButtonStyle {
  primary,
  secondary
}

class GemButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color gemColor;
  final bool isAnimated;
  final GemButtonStyle style;

  const GemButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gemColor = emerald,
    this.isAnimated = false,
    this.style = GemButtonStyle.primary,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: onPressed != null ? gemColor.withOpacity(0.2) : caveShadow.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(emeraldCut),
          side: BorderSide(
            color: onPressed != null ? gemColor.withOpacity(0.5) : silver.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Text(
        text,
        style: gemText.copyWith(
          color: onPressed != null ? gemColor : silver.withOpacity(0.5),
          fontSize: 16,
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