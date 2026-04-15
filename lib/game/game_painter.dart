import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class GamePainter extends CustomPainter {
  final GameState game;
  final Offset? aimPoint;

  GamePainter({required this.game, this.aimPoint});

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawTarget(canvas, game.targetCenter);
    _drawHitMarkers(canvas);
    if (aimPoint != null && game.phase == GamePhase.aiming) {
      _drawAimLine(canvas, size, aimPoint!);
    }
    if (game.flyingArrow != null) {
      _drawArrow(canvas, game.flyingArrow!);
    }
    _drawBow(canvas, size);
    if (game.phase == GamePhase.gameOver) {
      _drawGameOver(canvas, size);
    }
  }

  void _drawBackground(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1A2332);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Ground
    final groundPaint = Paint()..color = const Color(0xFF2D4A22);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3), groundPaint);
  }

  void _drawTarget(Canvas canvas, Offset center) {
    final rings = [
      (kTargetRadius, const Color(0xFF1A6B4A)),
      (kBullseyeRadius * 3, const Color(0xFF2196F3)),
      (kBullseyeRadius * 2, const Color(0xFFFF5722)),
      (kBullseyeRadius, const Color(0xFFFFEB3B)),
    ];

    for (final (r, c) in rings) {
      canvas.drawCircle(center, r, Paint()..color = c);
      canvas.drawCircle(center, r, Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Stand
    final standPaint = Paint()..color = const Color(0xFF795548)..strokeWidth = 4..style = PaintingStyle.stroke;
    canvas.drawLine(center + const Offset(0, kTargetRadius),
        center + const Offset(0, kTargetRadius + 60), standPaint);
  }

  void _drawHitMarkers(Canvas canvas) {
    final markerPaint = Paint()..color = Colors.white.withOpacity(0.7)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (final pos in game.hitPositions) {
      canvas.drawLine(pos + const Offset(-6, 0), pos + const Offset(6, 0), markerPaint);
      canvas.drawLine(pos + const Offset(0, -6), pos + const Offset(0, 6), markerPaint);
    }
  }

  void _drawAimLine(Canvas canvas, Size size, Offset aim) {
    final bowPos = Offset(size.width / 2, size.height * 0.85);
    final aimPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(bowPos.dx, bowPos.dy);

    // Draw dotted wind-affected trajectory preview
    for (int i = 0; i <= 20; i++) {
      final t = i / 20.0;
      final windDrift = game.windStrength * t * t * 80;
      final arcY = -sin(t * pi) * 60;
      final x = bowPos.dx + (aim.dx - bowPos.dx) * t + windDrift;
      final y = bowPos.dy + (aim.dy - bowPos.dy) * t + arcY;
      if (i == 0) path.moveTo(x, y);
      else if (i % 2 == 0) path.lineTo(x, y);
      else path.moveTo(x, y);
    }
    canvas.drawPath(path, aimPaint);

    // Aim crosshair
    final crossPaint = Paint()..color = Colors.redAccent.withOpacity(0.8)..strokeWidth = 1.5;
    canvas.drawLine(aim + const Offset(-10, 0), aim + const Offset(10, 0), crossPaint);
    canvas.drawLine(aim + const Offset(0, -10), aim + const Offset(0, 10), crossPaint);
    canvas.drawCircle(aim, 14, crossPaint..style = PaintingStyle.stroke);
  }

  void _drawArrow(Canvas canvas, Arrow arrow) {
    final arrowPaint = Paint()
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final dir = arrow.target - arrow.start;
    final angle = atan2(dir.dy, dir.dx);
    final tip = arrow.current;
    final tail = tip - Offset(cos(angle) * 30, sin(angle) * 30);
    canvas.drawLine(tail, tip, arrowPaint);

    // Arrowhead
    final headPaint = Paint()..color = const Color(0xFFBDBDBD);
    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(tip.dx - cos(angle - 0.4) * 10, tip.dy - sin(angle - 0.4) * 10);
    path.lineTo(tip.dx - cos(angle + 0.4) * 10, tip.dy - sin(angle + 0.4) * 10);
    path.close();
    canvas.drawPath(path, headPaint);
  }

  void _drawBow(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final bowPaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(center.dx - 8, center.dy - 25);
    path.quadraticBezierTo(center.dx - 20, center.dy, center.dx - 8, center.dy + 25);
    canvas.drawPath(path, bowPaint);

    // String
    final stringPaint = Paint()
      ..color = Colors.white60
      ..strokeWidth = 1.5;
    canvas.drawLine(
      center + const Offset(-8, -25),
      center + const Offset(-8, 25),
      stringPaint,
    );
  }

  void _drawGameOver(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlay);

    final tp = TextPainter(
      text: TextSpan(
        text: 'FINAL SCORE\n${game.totalScore}',
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: size.width);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 - 60));
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
