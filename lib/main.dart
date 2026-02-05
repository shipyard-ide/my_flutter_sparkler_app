import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '4th of July Sparkler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SparklerScreen(),
    );
  }
}

class SparklerScreen extends StatefulWidget {
  const SparklerScreen({super.key});

  @override
  State<SparklerScreen> createState() => _SparklerScreenState();
}

class _SparklerScreenState extends State<SparklerScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Spark> _sparks = [];
  final Random _random = Random();

  static const List<Color> sparkColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFFFFFF), // White
    Color(0xFFFF4444), // Red
    Color(0xFF4488FF), // Blue
    Color(0xFFFFA500), // Orange
    Color(0xFFFFE4B5), // Light gold
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateSparks);
    _controller.repeat();
  }

  void _updateSparks() {
    setState(() {
      final size = MediaQuery.of(context).size;
      final centerX = size.width / 2;
      final centerY = size.height / 2 - 60;

      // Add new sparks
      for (int i = 0; i < 8; i++) {
        final angle = _random.nextDouble() * 2 * pi;
        final speed = 2.0 + _random.nextDouble() * 4.0;
        final life = 0.5 + _random.nextDouble() * 0.8;

        _sparks.add(Spark(
          x: centerX,
          y: centerY,
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - 1.5,
          life: life,
          maxLife: life,
          color: sparkColors[_random.nextInt(sparkColors.length)],
          size: 1.5 + _random.nextDouble() * 2.5,
          trail: [],
        ));
      }

      // Update existing sparks
      for (var spark in _sparks) {
        spark.trail.add(Offset(spark.x, spark.y));
        if (spark.trail.length > 8) {
          spark.trail.removeAt(0);
        }

        spark.x += spark.vx;
        spark.y += spark.vy;
        spark.vy += 0.08; // gravity
        spark.vx *= 0.98; // drag
        spark.life -= 0.016;
      }

      // Remove dead sparks
      _sparks.removeWhere((spark) => spark.life <= 0);

      // Limit total sparks for performance
      if (_sparks.length > 400) {
        _sparks.removeRange(0, _sparks.length - 400);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: CustomPaint(
        painter: SparklerPainter(
          sparks: _sparks,
          centerX: MediaQuery.of(context).size.width / 2,
          centerY: MediaQuery.of(context).size.height / 2 - 60,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class Spark {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  double maxLife;
  Color color;
  double size;
  List<Offset> trail;

  Spark({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
    required this.trail,
  });
}

class SparklerPainter extends CustomPainter {
  final List<Spark> sparks;
  final double centerX;
  final double centerY;

  SparklerPainter({
    required this.sparks,
    required this.centerX,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw sparkler stick
    _drawSparklerStick(canvas);

    // Draw spark trails
    for (var spark in sparks) {
      if (spark.trail.length > 1) {
        final trailPaint = Paint()
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        for (int i = 0; i < spark.trail.length - 1; i++) {
          final opacity = (i / spark.trail.length) * (spark.life / spark.maxLife);
          trailPaint.color = spark.color.withValues(alpha: opacity * 0.6);
          trailPaint.strokeWidth = spark.size * (i / spark.trail.length) * 0.8;

          canvas.drawLine(spark.trail[i], spark.trail[i + 1], trailPaint);
        }
      }
    }

    // Draw sparks with glow
    for (var spark in sparks) {
      final opacity = (spark.life / spark.maxLife).clamp(0.0, 1.0);

      // Outer glow
      final glowPaint = Paint()
        ..color = spark.color.withValues(alpha: opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(spark.x, spark.y), spark.size * 2.5, glowPaint);

      // Inner glow
      final innerGlowPaint = Paint()
        ..color = spark.color.withValues(alpha: opacity * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(spark.x, spark.y), spark.size * 1.5, innerGlowPaint);

      // Core spark
      final sparkPaint = Paint()
        ..color = Color.lerp(spark.color, Colors.white, 0.5)!.withValues(alpha: opacity);
      canvas.drawCircle(Offset(spark.x, spark.y), spark.size, sparkPaint);
    }

    // Draw center glow (the burning tip)
    _drawCenterGlow(canvas);
  }

  void _drawSparklerStick(Canvas canvas) {
    final stickLength = 180.0;
    final stickTop = centerY + 5;
    final stickBottom = stickTop + stickLength;

    // Metallic gradient for the wire part
    final wireRect = Rect.fromPoints(
      Offset(centerX - 1.5, stickTop),
      Offset(centerX + 1.5, stickTop + 40),
    );
    final wirePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.grey.shade600,
          Colors.grey.shade300,
          Colors.grey.shade600,
        ],
      ).createShader(wireRect);
    canvas.drawRect(wireRect, wirePaint);

    // Burned/used coating at top
    final burnedPaint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, stickTop + 40),
      Offset(centerX, stickTop + 70),
      burnedPaint,
    );

    // Handle (paper/cardboard wrapped part)
    final handleTop = stickTop + 70;
    final handleRect = Rect.fromPoints(
      Offset(centerX - 3, handleTop),
      Offset(centerX + 3, stickBottom),
    );

    // Handle gradient
    final handlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF8B7355),
          const Color(0xFFD2B48C),
          const Color(0xFF8B7355),
        ],
      ).createShader(handleRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(1)),
      handlePaint,
    );

    // Handle stripes
    final stripePaint = Paint()
      ..color = const Color(0xFF654321).withValues(alpha: 0.3)
      ..strokeWidth = 6;
    for (double y = handleTop + 10; y < stickBottom - 5; y += 15) {
      canvas.drawLine(
        Offset(centerX - 3, y),
        Offset(centerX + 3, y),
        stripePaint,
      );
    }
  }

  void _drawCenterGlow(Canvas canvas) {
    // Intense white-hot core
    final corePaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(centerX, centerY), 4, corePaint);

    // Yellow/orange inner glow
    final innerPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(centerX, centerY), 10, innerPaint);

    // Orange mid glow
    final midPaint = Paint()
      ..color = const Color(0xFFFF8C00).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(centerX, centerY), 18, midPaint);

    // Red outer glow
    final outerPaint = Paint()
      ..color = const Color(0xFFFF4500).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawCircle(Offset(centerX, centerY), 30, outerPaint);

    // Ambient light effect
    final ambientPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(centerX, centerY), 60, ambientPaint);
  }

  @override
  bool shouldRepaint(covariant SparklerPainter oldDelegate) => true;
}
