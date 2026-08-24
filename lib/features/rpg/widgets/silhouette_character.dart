import 'dart:math';
import 'package:flutter/material.dart';

class SilhouetteCharacter extends StatelessWidget {
  final double size;
  final int level;

  const SilhouetteCharacter({super.key, this.size = 120, this.level = 1});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RuneCirclePainter(level: level)),
    );
  }
}

class _RuneCirclePainter extends CustomPainter {
  final int level;

  _RuneCirclePainter({required this.level});

  // Рисуем конкретные скандинавские руны
  void _drawRune(
    Canvas canvas,
    Offset center,
    double runeSize,
    String rune,
    Paint paint,
  ) {
    final s = runeSize;
    final dx = center.dx;
    final dy = center.dy;

    switch (rune) {
      case 'fehu': // ᚠ — Феху
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.5),
          Offset(dx - s * 0.3, dy + s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.5, dy - s * 0.5),
          Offset(dx - s * 0.3, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.1),
          Offset(dx - s * 0.1, dy - s * 0.1),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.3, dy - s * 0.4),
          Offset(dx + s * 0.1, dy - s * 0.4),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.3, dy - s * 0.4),
          Offset(dx + s * 0.3, dy + s * 0.4),
          paint,
        );
        break;
      case 'uruz': // ᚢ — Уруз
        canvas.drawLine(
          Offset(dx - s * 0.3, dy + s * 0.5),
          Offset(dx - s * 0.3, dy - s * 0.1),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.1),
          Offset(dx - s * 0.1, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.1, dy - s * 0.5),
          Offset(dx + s * 0.1, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.1, dy - s * 0.5),
          Offset(dx + s * 0.3, dy - s * 0.1),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.3, dy - s * 0.1),
          Offset(dx + s * 0.3, dy + s * 0.5),
          paint,
        );
        break;
      case 'thurisaz': // ᚦ — Турисаз
        canvas.drawLine(
          Offset(dx, dy - s * 0.6),
          Offset(dx, dy + s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.5),
          Offset(dx + s * 0.3, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.2, dy - s * 0.2),
          Offset(dx, dy - s * 0.2),
          paint,
        );
        canvas.drawLine(
          Offset(dx, dy - s * 0.2),
          Offset(dx, dy + s * 0.5),
          paint,
        );
        break;
      case 'ansuz': // ᚨ — Ансуз
        canvas.drawLine(
          Offset(dx, dy - s * 0.3),
          Offset(dx, dy + s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.1),
          Offset(dx + s * 0.3, dy - s * 0.1),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.1),
          Offset(dx, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.3, dy - s * 0.1),
          Offset(dx, dy - s * 0.5),
          paint,
        );
        break;
      case 'raido': // ᚱ — Райдо
        canvas.drawLine(
          Offset(dx - s * 0.2, dy - s * 0.5),
          Offset(dx - s * 0.2, dy + s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.2, dy - s * 0.5),
          Offset(dx + s * 0.2, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.2, dy - s * 0.5),
          Offset(dx + s * 0.2, dy - s * 0.1),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.2, dy - s * 0.1),
          Offset(dx, dy + s * 0.3),
          paint,
        );
        canvas.drawLine(
          Offset(dx, dy + s * 0.3),
          Offset(dx + s * 0.2, dy + s * 0.3),
          paint,
        );
        break;
      case 'kenaz': // ᚲ — Кеназ
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.3),
          Offset(dx + s * 0.3, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.3),
          Offset(dx - s * 0.3, dy + s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.3, dy + s * 0.5),
          Offset(dx + s * 0.3, dy + s * 0.3),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.3, dy - s * 0.5),
          Offset(dx + s * 0.3, dy + s * 0.3),
          paint,
        );
        break;
      case 'gebo': // ᚷ — Гебо
        canvas.drawLine(
          Offset(dx - s * 0.3, dy - s * 0.3),
          Offset(dx + s * 0.3, dy + s * 0.3),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.3, dy - s * 0.3),
          Offset(dx - s * 0.3, dy + s * 0.3),
          paint,
        );
        break;
      case 'wunjo': // ᚹ — Вуньо
        canvas.drawLine(
          Offset(dx - s * 0.2, dy + s * 0.5),
          Offset(dx - s * 0.2, dy - s * 0.5),
          paint,
        );
        canvas.drawLine(
          Offset(dx - s * 0.2, dy - s * 0.5),
          Offset(dx + s * 0.2, dy - s * 0.3),
          paint,
        );
        canvas.drawLine(
          Offset(dx + s * 0.2, dy - s * 0.3),
          Offset(dx + s * 0.2, dy + s * 0.3),
          paint,
        );
        break;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final c = Offset(w / 2, w / 2);

    // ======== ФОН ========
    canvas.drawCircle(c, w / 2, Paint()..color = Color(0xFF1A1A2E));

    // ======== КРУГИ ========
    canvas.drawCircle(
      c,
      w / 2 - 3,
      Paint()
        ..color = Color(0xFFD4A574)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    canvas.drawCircle(
      c,
      w * 0.42,
      Paint()
        ..color = Color(0xFF6B3FA0).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      c,
      w * 0.25,
      Paint()
        ..color = Color(0xFF6B3FA0).withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ======== РУНЫ ========
    final runePaint = Paint()
      ..color = Color(0xFFD4A574)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final runeNames = [
      'fehu',
      'uruz',
      'thurisaz',
      'ansuz',
      'raido',
      'kenaz',
      'gebo',
      'wunjo',
    ];

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final r = w * 0.33;
      final x = c.dx + r * cos(angle);
      final y = c.dy + r * sin(angle);
      _drawRune(canvas, Offset(x, y), w * 0.09, runeNames[i], runePaint);
    }

    // ======== УРОВЕНЬ ========
    if (level > 0) {
      final levelPainter = TextPainter(
        text: TextSpan(
          text: '$level',
          style: TextStyle(
            color: Color(0xFFD4A574),
            fontSize: w * 0.24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      levelPainter.paint(
        canvas,
        Offset(
          c.dx - levelPainter.width / 2,
          c.dy - levelPainter.height / 2 - w * 0.05,
        ),
      );

      final lvlPainter = TextPainter(
        text: TextSpan(
          text: 'LVL',
          style: TextStyle(
            color: Color(0xFFD4A574).withValues(alpha: 0.6),
            fontSize: w * 0.07,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      lvlPainter.paint(
        canvas,
        Offset(c.dx - lvlPainter.width / 2, c.dy + w * 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RuneCirclePainter oldDelegate) {
    return oldDelegate.level != level;
  }
}
