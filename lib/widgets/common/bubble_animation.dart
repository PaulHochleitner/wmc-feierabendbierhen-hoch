import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Model für eine einzelne Blase in der Animation
class Bubble {
  final double x;
  final double y;
  final double size;
  final double speed;

  Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

/// CustomPainter für die Blasen-Animation
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;

  BubblePainter({
    required this.bubbles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var bubble in bubbles) {
      // Berechne Y-Position basierend auf Animation (Looping)
      // Blasen steigen nach oben
      double currentY = (bubble.y - (animationValue * bubble.speed)) % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Zeichne Blase
      canvas.drawCircle(
        Offset(bubble.x * size.width, currentY * size.height),
        bubble.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Utility-Klasse zum Erstellen von Blasen-Listen
class BubbleGenerator {
  static List<Bubble> generateBubbles({
    int count = AppConstants.bubbleCount,
    Random? random,
  }) {
    final rng = random ?? Random();
    return List.generate(
      count,
      (index) => Bubble(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 2 + rng.nextDouble() * 4,
        speed: 0.3 + rng.nextDouble() * 0.7,
      ),
    );
  }
}
