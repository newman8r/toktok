import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/gem_theme.dart';

class CaveBackgroundPainter extends CustomPainter {
  final double ambientProgress;
  final double parallaxOffset;
  final List<Crystal> _crystals;
  
  static const int crystalCount = 15;
  
  CaveBackgroundPainter({
    required this.ambientProgress,
    required this.parallaxOffset,
  }) : _crystals = List.generate(crystalCount, (index) {
    final random = math.Random(index);
    return Crystal(
      position: Offset(
        random.nextDouble() * 2 - 1,
        random.nextDouble() * 2 - 1,
      ),
      size: 50 + random.nextDouble() * 100,
      rotation: random.nextDouble() * math.pi,
      color: [amethyst, emerald, sapphire, ruby][random.nextInt(4)],
      depth: 0.5 + random.nextDouble() * 0.5,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ambient background
    final backgroundGradient = RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [
        deepCave,
        caveShadow.withOpacity(0.5),
        deepCave,
      ],
      stops: [0.0, 0.5, 1.0],
    );
    
    final backgroundRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final backgroundPaint = Paint()
      ..shader = backgroundGradient.createShader(backgroundRect);
    canvas.drawRect(backgroundRect, backgroundPaint);

    // Draw crystals with parallax
    for (final crystal in _crystals) {
      final adjustedPosition = Offset(
        (crystal.position.dx * size.width) + (parallaxOffset * crystal.depth),
        (crystal.position.dy * size.height) + (parallaxOffset * crystal.depth * 0.5),
      );
      
      _drawCrystal(
        canvas,
        adjustedPosition,
        crystal.size,
        crystal.rotation,
        crystal.color,
        crystal.depth,
      );
    }
  }

  void _drawCrystal(
    Canvas canvas,
    Offset position,
    double size,
    double rotation,
    Color color,
    double depth,
  ) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation + (ambientProgress * 0.05));

    final crystalPath = Path();
    final points = <Offset>[];
    
    // Create crystal shape
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (math.sin(ambientProgress * math.pi * 2) * 0.1);
      final radius = size * (0.5 + math.cos(angle * 2) * 0.2);
      points.add(Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      ));
    }

    crystalPath.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      crystalPath.lineTo(points[i].dx, points[i].dy);
    }
    crystalPath.close();

    // Crystal fill
    final crystalPaint = Paint()
      ..color = color.withOpacity(0.1 + (depth * 0.2))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5);
    
    canvas.drawPath(crystalPath, crystalPaint);

    // Crystal outline
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.3 + (math.sin(ambientProgress * math.pi * 2) * 0.1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawPath(crystalPath, outlinePaint);

    // Crystal glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.1 * (1 + math.sin(ambientProgress * math.pi * 2)))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawPath(crystalPath, glowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(CaveBackgroundPainter oldDelegate) {
    return oldDelegate.ambientProgress != ambientProgress ||
           oldDelegate.parallaxOffset != parallaxOffset;
  }
}

class Crystal {
  final Offset position;
  final double size;
  final double rotation;
  final Color color;
  final double depth;

  Crystal({
    required this.position,
    required this.size,
    required this.rotation,
    required this.color,
    required this.depth,
  });
} 