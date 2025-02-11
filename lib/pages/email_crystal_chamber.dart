import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/gem_theme.dart';
import '../widgets/gem_button.dart';
import '../services/resend_service.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';

class EmailCrystalChamber extends StatefulWidget {
  final String cloudinaryUrl;
  
  const EmailCrystalChamber({
    super.key,
    required this.cloudinaryUrl,
  });

  @override
  State<EmailCrystalChamber> createState() => _EmailCrystalChamberState();
}

class _EmailCrystalChamberState extends State<EmailCrystalChamber> with TickerProviderStateMixin {
  final _resendService = ResendService();
  late final AnimationController _glitchController;
  late final AnimationController _dataStreamController;
  late final AnimationController _crystalController;
  late final AnimationController _energyController;
  late final AnimationController _successController;
  
  final List<Offset> _crystalPoints = [];
  final _random = math.Random();
  bool _isSending = false;
  bool _isSuccess = false;
  String? _errorMessage;
  final TextEditingController _emailController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Glitch effect - rapid and chaotic
    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
    
    // Data stream flow - smooth and continuous
    _dataStreamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    // Crystal pulsing - slow and hypnotic
    _crystalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    // Energy beam - medium speed with irregularity
    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _generateCrystalPoints();
  }
  
  void _generateCrystalPoints() {
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final radius = 150.0 + _random.nextDouble() * 50;
      _crystalPoints.add(Offset(
        math.cos(angle) * radius,
        math.sin(angle) * radius,
      ));
    }
  }
  
  void _sendEmail() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();
    
    final success = await _resendService.sendGemShareEmail(
      toEmail: _emailController.text,
      gemUrl: widget.cloudinaryUrl,
    );
    
    if (mounted) {
      setState(() {
        _isSending = false;
        if (success) {
          _isSuccess = true;
          _successController.forward();
          HapticFeedback.mediumImpact();
        } else {
          _errorMessage = 'Failed to send email. Please try again.';
          HapticFeedback.heavyImpact();
        }
      });
    }
  }
  
  @override
  void dispose() {
    _glitchController.dispose();
    _dataStreamController.dispose();
    _crystalController.dispose();
    _energyController.dispose();
    _successController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepCave,
      body: Stack(
        children: [
          // Glitchy crystal background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _glitchController,
                _dataStreamController,
                _crystalController,
                _energyController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _GlitchyChamberPainter(
                    crystalPoints: _crystalPoints,
                    glitchValue: _glitchController.value,
                    dataStreamProgress: _dataStreamController.value,
                    crystalPulse: _crystalController.value,
                    energyValue: _energyController.value,
                    sendProgress: _isSending ? 0.5 : 0,
                  ),
                );
              },
            ),
          ),
          
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: silver),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Text(
                          'Share Crystal Link',
                          style: crystalHeading.copyWith(
                            fontSize: 24,
                            foreground: Paint()
                              ..shader = LinearGradient(
                                colors: [
                                  sapphire,
                                  sapphire.withOpacity(0.7),
                                ],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 200, 70)
                              ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  if (_isSuccess) 
                    // Success message
                    FadeTransition(
                      opacity: _successController,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: sapphire,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Video sent successfully!',
                            style: crystalHeading.copyWith(
                              fontSize: 24,
                              color: sapphire,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your recipient will receive it shortly',
                            style: gemText.copyWith(
                              color: silver,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 32),
                          GemButton(
                            text: 'Back to Gallery',
                            onPressed: () => Navigator.pop(context),
                            gemColor: sapphire,
                            style: GemButtonStyle.secondary,
                            isAnimated: true,
                          ),
                        ],
                      ),
                    )
                  else
                    // Email input and controls
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: caveShadow.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(brilliantCut),
                          border: Border.all(
                            color: sapphire.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_errorMessage != null) ...[
                              Text(
                                _errorMessage!,
                                style: crystalHeading.copyWith(
                                  fontSize: 18,
                                  color: ruby,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            TextField(
                              controller: _emailController,
                              style: crystalHeading.copyWith(
                                fontSize: 16,
                                color: silver,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter email address',
                                hintStyle: crystalHeading.copyWith(
                                  fontSize: 16,
                                  color: silver.withOpacity(0.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(brilliantCut / 2),
                                  borderSide: BorderSide(
                                    color: sapphire.withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(brilliantCut / 2),
                                  borderSide: BorderSide(
                                    color: sapphire,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            GemButton(
                              text: _isSending ? 'Sending...' : 'Send Crystal Link',
                              onPressed: _isSending ? () {} : _sendEmail,
                              gemColor: sapphire,
                              isAnimated: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlitchyChamberPainter extends CustomPainter {
  final List<Offset> crystalPoints;
  final double glitchValue;
  final double dataStreamProgress;
  final double crystalPulse;
  final double energyValue;
  final double sendProgress;
  
  _GlitchyChamberPainter({
    required this.crystalPoints,
    required this.glitchValue,
    required this.dataStreamProgress,
    required this.crystalPulse,
    required this.energyValue,
    required this.sendProgress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw energy field
    _drawEnergyField(canvas, size, center);
    
    // Draw crystal formations
    for (var point in crystalPoints) {
      _drawGlitchyCrystal(
        canvas, 
        point.translate(center.dx, center.dy),
      );
    }
    
    // Draw data streams
    _drawDataStreams(canvas, size, center);
    
    // Draw corruption effects
    if (sendProgress > 0) {
      _drawCorruption(canvas, size, center);
    }
  }
  
  void _drawEnergyField(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          sapphire.withOpacity(0.2 * energyValue),
          sapphire.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCenter(
        center: center,
        width: size.width,
        height: size.height,
      ));
    
    canvas.drawRect(Offset.zero & size, paint);
  }
  
  void _drawGlitchyCrystal(Canvas canvas, Offset center) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          sapphire.withOpacity(0.8),
          sapphire.withOpacity(0.3),
        ],
        transform: GradientRotation(dataStreamProgress * math.pi * 2),
      ).createShader(Rect.fromCenter(
        center: center,
        width: 100,
        height: 100,
      ));
    
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * math.pi * 2;
      final radius = 30.0 * (1 + crystalPulse * 0.2);
      final glitchOffset = sendProgress > 0 
        ? (glitchValue * 10 * sendProgress)
        : (glitchValue * 5);
      final point = Offset(
        center.dx + math.cos(angle) * radius + glitchOffset,
        center.dy + math.sin(angle) * radius,
      );
      
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  void _drawDataStreams(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = sapphire.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
      
    for (var point in crystalPoints) {
      final path = Path();
      final start = center;
      final end = point.translate(center.dx, center.dy);
      
      path.moveTo(start.dx, start.dy);
      
      // Create a glitchy path
      for (var i = 0; i < 5; i++) {
        final t = i / 4;
        final mid = Offset(
          start.dx + (end.dx - start.dx) * t,
          start.dy + (end.dy - start.dy) * t,
        );
        
        // Add glitch offset
        final offset = Offset(
          math.Random().nextDouble() * 20 - 10,
          math.Random().nextDouble() * 20 - 10,
        );
        
        path.lineTo(
          mid.dx + offset.dx * glitchValue * (1 + sendProgress),
          mid.dy + offset.dy * glitchValue * (1 + sendProgress),
        );
      }
      
      path.lineTo(end.dx, end.dy);
      
      canvas.drawPath(path, paint);
    }
  }
  
  void _drawCorruption(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..color = sapphire.withOpacity(0.1 * sendProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    for (var i = 0; i < (20 * sendProgress).toInt(); i++) {
      final path = Path();
      final startAngle = math.Random().nextDouble() * math.pi * 2;
      final startRadius = math.Random().nextDouble() * size.width / 2;
      
      path.moveTo(
        center.dx + math.cos(startAngle) * startRadius,
        center.dy + math.sin(startAngle) * startRadius,
      );
      
      for (var j = 0; j < 5; j++) {
        final angle = startAngle + math.Random().nextDouble() * math.pi / 2;
        final radius = startRadius + math.Random().nextDouble() * 100;
        
        path.lineTo(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        );
      }
      
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(_GlitchyChamberPainter oldDelegate) {
    return oldDelegate.glitchValue != glitchValue ||
           oldDelegate.dataStreamProgress != dataStreamProgress ||
           oldDelegate.crystalPulse != crystalPulse ||
           oldDelegate.energyValue != energyValue ||
           oldDelegate.sendProgress != sendProgress;
  }
} 