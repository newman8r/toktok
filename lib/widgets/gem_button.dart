import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../theme/gem_theme.dart';

class GemButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color gemColor;
  final bool isAnimated;

  const GemButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.gemColor = amethyst,
    this.isAnimated = true,
  });

  @override
  State<GemButton> createState() => _GemButtonState();
}

class _GemButtonState extends State<GemButton> with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;
  late List<Offset> _sparklePoints;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Generate random sparkle points
    _sparklePoints = List.generate(12, (index) {
      return Offset(
        math.Random().nextDouble() * 2 - 1,
        math.Random().nextDouble() * 2 - 1,
      );
    });
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.05 : 1.0),
        child: Stack(
          children: [
            // Sparkle effect layer
            if (widget.isAnimated)
              AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _SparkleEffectPainter(
                      color: widget.gemColor,
                      progress: _sparkleController.value,
                      sparklePoints: _sparklePoints,
                      isHovered: _isHovered,
                    ),
                    child: child,
                  );
                },
                child: _buildButton(),
              ),
            
            // Base button
            if (!widget.isAnimated) _buildButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.gemColor.withOpacity(0.8),
            widget.gemColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(emeraldCut),
        boxShadow: [
          BoxShadow(
            color: widget.gemColor.withOpacity(0.3),
            blurRadius: _isHovered ? 15 : 10,
            spreadRadius: _isHovered ? 2 : 0,
          ),
          BoxShadow(
            color: widget.gemColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.onPressed();
          },
          borderRadius: BorderRadius.circular(emeraldCut),
          splashColor: widget.gemColor.withOpacity(0.3),
          highlightColor: widget.gemColor.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text(
              widget.text,
              style: gemText.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: widget.gemColor.withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
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