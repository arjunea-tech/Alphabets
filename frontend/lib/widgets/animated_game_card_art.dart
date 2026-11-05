import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated living game canvas overlay for game cards in the Games Screen.
/// Provides continuous, hardware-accelerated 60 FPS Pixar-style animations
/// (moving race car with smoke, flappy bird with flapping wings, ninja katana slashes,
/// floating balloons with confetti bursts, runner with speed dust, swimming fish, etc.)
class AnimatedGameCardArt extends StatelessWidget {
  final String gameType;
  final double time; // Continuously advancing normalized time (0.0 .. 1.0+)

  const AnimatedGameCardArt({
    super.key,
    required this.gameType,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GameCardArtPainter(
          gameType: gameType,
          time: time,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GameCardArtPainter extends CustomPainter {
  final String gameType;
  final double time;

  _GameCardArtPainter({
    required this.gameType,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    switch (gameType) {
      case 'racing':
        _paintRacing(canvas, size);
        break;
      case 'flappy':
        _paintFlappy(canvas, size);
        break;
      case 'ninja':
        _paintNinja(canvas, size);
        break;
      case 'balloon':
        _paintBalloon(canvas, size);
        break;
      case 'runner':
        _paintRunner(canvas, size);
        break;
      case 'candy':
        _paintCandy(canvas, size);
        break;
      case 'fishing':
        _paintFishing(canvas, size);
        break;
      case 'basket':
        _paintBasket(canvas, size);
        break;
      case 'matching':
        _paintMatching(canvas, size);
        break;
      case 'puzzle':
      default:
        _paintPuzzle(canvas, size);
        break;
    }
  }

  // =========================================================================
  // 1. CAR RACING: Moving sports car, speeding road dashes, exhaust smoke & wind streaks
  // =========================================================================
  void _paintRacing(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;
    final roadY = h * 0.76;

    // 1. Asphalt Road
    final roadRect = Rect.fromLTWH(0, roadY, w, h - roadY);
    final roadPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0F172A).withValues(alpha: 0.85),
          const Color(0xFF1E293B).withValues(alpha: 0.95),
        ],
      ).createShader(roadRect);
    canvas.drawRect(roadRect, roadPaint);

    // Road top border curb (Red & White racing curb)
    const curbW = 14.0;
    for (double cx = 0; cx < w + curbW; cx += curbW) {
      final shiftedX = (cx - (time * 160) % curbW);
      final isRed = ((cx / curbW).floor() % 2 == 0);
      canvas.drawRect(
        Rect.fromLTWH(shiftedX, roadY - 3, curbW, 3),
        Paint()..color = isRed ? const Color(0xFFEF4444) : Colors.white,
      );
    }

    // Moving Dashed Center Line
    const dashW = 18.0;
    const dashGap = 14.0;
    const totalStep = dashW + dashGap;
    final dashOffset = (time * 220) % totalStep;
    final dashPaint = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.90)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (double dx = -totalStep; dx < w + totalStep; dx += totalStep) {
      final x1 = dx - dashOffset;
      final x2 = x1 + dashW;
      if (x2 > 0 && x1 < w) {
        canvas.drawLine(Offset(x1, roadY + 12), Offset(x2, roadY + 12), dashPaint);
      }
    }

    // 2. Speed Wind Streaks
    final streakPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final sy = h * 0.25 + i * 16.0;
      final sx = (w + 40 - ((time * 300 + i * 55) % (w + 80)));
      canvas.drawLine(Offset(sx, sy), Offset(sx + 28, sy), streakPaint);
    }

    // 3. Cartoon Race Car
    final carX = w * 0.40 + math.sin(t * 1.5) * 12.0;
    final carBounce = (math.sin(t * 14.0).abs()) * 1.8;
    final carY = roadY - 14.0 - carBounce;

    // Headlight Yellow Beam illuminating the road
    final beamPath = Path()
      ..moveTo(carX + 32, carY - 2)
      ..lineTo(w, roadY - 4)
      ..lineTo(w, roadY + 20)
      ..lineTo(carX + 30, carY + 8)
      ..close();
    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFDE047).withValues(alpha: 0.45),
            Colors.transparent,
          ],
        ).createShader(beamPath.getBounds()),
    );

    // Exhaust Smoke Rings (trailing behind)
    for (int p = 0; p < 4; p++) {
      final pTime = (time * 4.0 + p * 0.25) % 1.0;
      final smokeX = carX - 28.0 - pTime * 45.0;
      final smokeY = carY + 4.0 - pTime * 8.0 + math.sin(pTime * 8) * 3;
      final smokeR = 3.0 + pTime * 8.0;
      final smokeAlpha = (1.0 - pTime).clamp(0.0, 1.0) * 0.45;
      canvas.drawCircle(
        Offset(smokeX, smokeY),
        smokeR,
        Paint()..color = Colors.white.withValues(alpha: smokeAlpha),
      );
    }

    // Car Body (Aerodynamic Red Sports Car)
    final carBodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(carX - 25, carY - 6, 55, 14),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      carBodyRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF87171), Color(0xFFEF4444), Color(0xFFB91C1C)],
        ).createShader(carBodyRect.outerRect),
    );

    // Car Cabin / Windshield
    final cabinPath = Path()
      ..moveTo(carX - 10, carY - 6)
      ..lineTo(carX - 2, carY - 14)
      ..lineTo(carX + 16, carY - 14)
      ..lineTo(carX + 24, carY - 6)
      ..close();
    canvas.drawPath(
      cabinPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
        ).createShader(cabinPath.getBounds()),
    );
    // Windshield Glare
    canvas.drawLine(
      Offset(carX + 2, carY - 12),
      Offset(carX + 12, carY - 7),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.70)
        ..strokeWidth = 1.8,
    );

    // Rear Spoiler Wing
    canvas.drawLine(
      Offset(carX - 24, carY - 6),
      Offset(carX - 24, carY - 14),
      Paint()
        ..color = const Color(0xFF7F1D1D)
        ..strokeWidth = 2.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(carX - 27, carY - 16, 10, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFBBF24),
    );

    // Wheels (Front & Rear spinning tires)
    final wheelAngles = time * 28.0;
    _drawSpinningWheel(canvas, Offset(carX - 14, carY + 8), 7.5, wheelAngles);
    _drawSpinningWheel(canvas, Offset(carX + 18, carY + 8), 7.5, wheelAngles);

    // Speed Sparks under tires
    if ((time * 10).floor() % 2 == 0) {
      canvas.drawCircle(
        Offset(carX - 22, carY + 14),
        2.0,
        Paint()..color = const Color(0xFFFBBF24),
      );
    }
  }

  void _drawSpinningWheel(Canvas canvas, Offset center, double r, double angle) {
    // Tire Drop Shadow
    canvas.drawCircle(center.translate(0, 2), r, Paint()..color = Colors.black45);
    // Tire Rubber
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFF1E293B));
    // Silver Rim
    canvas.drawCircle(center, r * 0.65, Paint()..color = const Color(0xFFE2E8F0));
    // Gold Hubcap
    canvas.drawCircle(center, r * 0.28, Paint()..color = const Color(0xFFF59E0B));
    // Spokes
    final sp = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 4; i++) {
      final a = angle + i * (math.pi / 2);
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(a) * r * 0.60, center.dy + math.sin(a) * r * 0.60),
        sp,
      );
    }
  }

  // =========================================================================
  // 2. FLAPPY WORD: Yellow chick flapping wings, bobbing, clouds & star trail
  // =========================================================================
  void _paintFlappy(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    // 1. Drifting Parallax Clouds
    for (int i = 0; i < 3; i++) {
      final speed = 35.0 + i * 20.0;
      final cx = (w + 40 - ((time * speed + i * 75) % (w + 80)));
      final cy = h * 0.20 + i * 26.0;
      final cr = 14.0 + i * 4.0;
      _drawCloudPuff(canvas, Offset(cx, cy), cr, 0.40 - i * 0.08);
    }

    // 2. Bird Position with buoyancy
    final birdX = w * 0.40;
    final birdY = h * 0.48 + math.sin(t * 2.2) * 9.0;
    final tilt = math.sin(t * 2.2) * 0.16;

    canvas.save();
    canvas.translate(birdX, birdY);
    canvas.rotate(tilt);

    // Trailing Magic Sparkles
    for (int s = 0; s < 5; s++) {
      final sTime = (time * 3.5 + s * 0.2) % 1.0;
      final sx = -18.0 - sTime * 42.0;
      final sy = math.sin((time * 6 + s) * 2) * 6.0;
      final sAlpha = (1.0 - sTime).clamp(0.0, 1.0) * 0.8;
      final color = [
        const Color(0xFFFBBF24),
        const Color(0xFF38BDF8),
        const Color(0xFFEC4899),
        const Color(0xFF10B981),
      ][s % 4];

      _drawSparkleStar(canvas, Offset(sx, sy), (3.0 - sTime * 1.5).clamp(1.0, 4.0), color.withValues(alpha: sAlpha));
    }

    // Bird Body (Glossy Yellow Chick)
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.25),
        radius: 0.9,
        colors: [Color(0xFFFEF08A), Color(0xFFFBBF24), Color(0xFFF59E0B)],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 17));
    canvas.drawCircle(Offset.zero, 17, bodyPaint);

    // Rosy Blush Cheek
    canvas.drawCircle(
      const Offset(4, 4),
      4.5,
      Paint()..color = const Color(0xFFFB7185).withValues(alpha: 0.55),
    );

    // Anime Eye
    canvas.drawCircle(const Offset(6, -4), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(7, -4), 2.8, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(const Offset(8, -5.5), 1.2, Paint()..color = Colors.white);

    // Cute Orange Beak
    final beakPath = Path()
      ..moveTo(13, -2)
      ..lineTo(22, 1)
      ..lineTo(13, 5)
      ..close();
    canvas.drawPath(
      beakPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFB923C), Color(0xFFEA580C)],
        ).createShader(beakPath.getBounds()),
    );

    // Flapping Wing
    final wingFlap = math.sin(t * 7.5);
    final wingY = wingFlap * 5.0;
    final wingPath = Path()
      ..moveTo(-8, -2)
      ..quadraticBezierTo(-1, -8 + wingY, 6, -2 + wingY)
      ..quadraticBezierTo(2, 6, -8, -2)
      ..close();
    canvas.drawPath(
      wingPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFEAB308)],
        ).createShader(wingPath.getBounds()),
    );

    canvas.restore();
  }

  void _drawCloudPuff(Canvas canvas, Offset center, double r, double alpha) {
    final p = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawCircle(center, r, p);
    canvas.drawCircle(Offset(center.dx - r * 0.7, center.dy + r * 0.2), r * 0.75, p);
    canvas.drawCircle(Offset(center.dx + r * 0.7, center.dy + r * 0.1), r * 0.70, p);
  }

  void _drawSparkleStar(Canvas canvas, Offset center, double size, Color color) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + size)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - size, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, p);
  }

  // =========================================================================
  // 3. WORD NINJA: Katana slash swipe trail, split fruit halves & juice splatter
  // =========================================================================
  void _paintNinja(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cycle duration = 2.0s
    final cycleTime = (time * 1.5) % 1.0;
    final isSlashing = cycleTime < 0.35;
    final isExploding = cycleTime >= 0.35 && cycleTime < 0.85;
    final fruitCenter = Offset(w * 0.50, h * 0.50);

    // 1. Fruit / Sliced Halves
    if (!isExploding) {
      // Whole Fruit Flying Up and Down in an arc
      final arcY = fruitCenter.dy + math.sin(cycleTime * math.pi) * -12.0;
      _drawWatermelon(canvas, Offset(fruitCenter.dx, arcY), 22.0);
    } else {
      // Sliced Halves Exploding Apart!
      final popProgress = (cycleTime - 0.35) / 0.50; // 0.0 -> 1.0
      final spread = popProgress * 26.0;
      final drop = popProgress * 18.0;
      final alpha = (1.0 - popProgress * 0.85).clamp(0.0, 1.0);

      // Left Half
      canvas.save();
      canvas.translate(fruitCenter.dx - spread, fruitCenter.dy + drop);
      canvas.rotate(-popProgress * 0.6);
      _drawHalfWatermelon(canvas, 22.0, true, alpha);
      canvas.restore();

      // Right Half
      canvas.save();
      canvas.translate(fruitCenter.dx + spread, fruitCenter.dy + drop + 4);
      canvas.rotate(popProgress * 0.6);
      _drawHalfWatermelon(canvas, 22.0, false, alpha);
      canvas.restore();

      // Juice Splatter Drops
      for (int i = 0; i < 7; i++) {
        final ang = i * (math.pi * 2 / 7);
        final dist = 16.0 + popProgress * 40.0;
        final jx = fruitCenter.dx + math.cos(ang) * dist;
        final jy = fruitCenter.dy + math.sin(ang) * dist;
        canvas.drawCircle(
          Offset(jx, jy),
          (3.0 - popProgress * 2.0).clamp(0.8, 3.5),
          Paint()..color = const Color(0xFFEF4444).withValues(alpha: alpha * 0.8),
        );
      }
    }

    // 2. Glowing Katana Slash Swipe (Arcs diagonally across screen)
    if (isSlashing) {
      final slashP = cycleTime / 0.35; // 0.0 -> 1.0
      final startX = w * 0.15;
      final startY = h * 0.25;
      final endX = w * 0.85;
      final endY = h * 0.75;

      final currentX = startX + (endX - startX) * slashP;
      final currentY = startY + (endY - startY) * slashP;

      // Cyan outer glow
      final slashGlow = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.65)
        ..strokeWidth = 7.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawLine(Offset(startX, startY), Offset(currentX, currentY), slashGlow);

      // White core blade laser
      final slashCore = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(startX, startY), Offset(currentX, currentY), slashCore);

      // Slash Impact Spark Starburst
      if (slashP > 0.45) {
        _drawSparkleStar(canvas, fruitCenter, 14.0 * slashP, const Color(0xFFFDE047));
      }
    }
  }

  void _drawWatermelon(Canvas canvas, Offset center, double r) {
    // Green outer skin
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF22C55E), Color(0xFF15803D), Color(0xFF052E16)],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
    // Dark stripes
    final sp = Paint()
      ..color = const Color(0xFF052E16).withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r * 0.75), -0.8, 1.6, false, sp);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r * 0.75), math.pi - 0.8, 1.6, false, sp);
  }

  void _drawHalfWatermelon(Canvas canvas, double r, bool isLeft, double alpha) {
    final startAng = isLeft ? math.pi * 0.5 : -math.pi * 0.5;
    const sweep = math.pi;

    // Green Rind
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r),
      startAng,
      sweep,
      true,
      Paint()..color = const Color(0xFF15803D).withValues(alpha: alpha),
    );
    // Inner Light Rind
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.88),
      startAng,
      sweep,
      true,
      Paint()..color = const Color(0xFFDCFCE7).withValues(alpha: alpha),
    );
    // Red Juicy Flesh
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.78),
      startAng,
      sweep,
      true,
      Paint()..color = const Color(0xFFEF4444).withValues(alpha: alpha),
    );
  }

  // =========================================================================
  // 4. BALLOON POP: Multiple candy balloons bobbing & rising with popping confetti
  // =========================================================================
  void _paintBalloon(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final balloons = [
      {'color': const Color(0xFF06B6D4), 'x': w * 0.22, 'speed': 45.0, 'offset': 0.0, 'r': 18.0, 'letter': 'A'},
      {'color': const Color(0xFFEC4899), 'x': w * 0.50, 'speed': 55.0, 'offset': 0.35, 'r': 21.0, 'letter': 'E'},
      {'color': const Color(0xFFF59E0B), 'x': w * 0.78, 'speed': 48.0, 'offset': 0.70, 'r': 19.0, 'letter': 'O'},
    ];

    for (final b in balloons) {
      final speed = b['speed'] as double;
      final offset = b['offset'] as double;
      final r = b['r'] as double;
      final color = b['color'] as Color;
      final bx = b['x'] as double;
      final letter = b['letter'] as String;

      final loopPeriod = (h + 80) / speed;
      final pTime = (time * loopPeriod * 0.15 + offset) % 1.0;
      final by = (h + 40) - pTime * (h + 80);
      final sway = math.sin((time * 3.0 + offset * 5) * math.pi) * 6.0;

      final balloonPos = Offset(bx + sway, by);

      // Wavy String
      final stringPath = Path()
        ..moveTo(balloonPos.dx, balloonPos.dy + r)
        ..quadraticBezierTo(balloonPos.dx - 4, balloonPos.dy + r + 10, balloonPos.dx + 2, balloonPos.dy + r + 22);
      canvas.drawPath(
        stringPath,
        Paint()
          ..color = Colors.white70
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );

      // Balloon Body (Glossy 3D Oval)
      final balloonRect = Rect.fromCenter(
        center: balloonPos,
        width: r * 1.85,
        height: r * 2.35,
      );
      final balloonPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.9,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(balloonRect);
      canvas.drawOval(balloonRect, balloonPaint);

      // Specular Highlight Glare
      final glareRect = Rect.fromCenter(
        center: Offset(balloonPos.dx - r * 0.35, balloonPos.dy - r * 0.45),
        width: r * 0.5,
        height: r * 0.7,
      );
      canvas.drawOval(
        glareRect,
        Paint()..color = Colors.white.withValues(alpha: 0.55),
      );

      // Stamped Letter on Balloon
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(balloonPos.dx - tp.width / 2, balloonPos.dy - tp.height / 2));
    }

    // Occasional Star Confetti Pop at top right
    final popCycle = (time * 1.8) % 1.0;
    if (popCycle < 0.45) {
      final burstCenter = Offset(w * 0.65, h * 0.30);
      final p = popCycle / 0.45;
      for (int i = 0; i < 6; i++) {
        final a = i * (math.pi / 3);
        final d = p * 28.0;
        final px = burstCenter.dx + math.cos(a) * d;
        final py = burstCenter.dy + math.sin(a) * d;
        final alpha = (1.0 - p).clamp(0.0, 1.0);
        _drawSparkleStar(canvas, Offset(px, py), 3.5, const Color(0xFFFDE047).withValues(alpha: alpha));
      }
    }
  }

  // =========================================================================
  // 5. RUNNER: 2D kid runner running, bouncing stride, speed dust & golden stars
  // =========================================================================
  void _paintRunner(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.75;

    // Grass Ledge at bottom
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, h - groundY),
      Paint()..color = const Color(0xFF059669).withValues(alpha: 0.85),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, w, 4),
      Paint()..color = const Color(0xFF34D399),
    );

    // Runner Kid
    final runnerX = w * 0.38;
    final stride = math.sin(t * 8.0);
    final runnerY = groundY - 26.0 - stride.abs() * 4.5;

    // Running Dust Puffs behind feet
    for (int i = 0; i < 3; i++) {
      final pTime = (time * 6.0 + i * 0.33) % 1.0;
      final dx = runnerX - 16.0 - pTime * 28.0;
      final dy = groundY - 2.0 - pTime * 5.0;
      final r = 2.0 + pTime * 5.0;
      final alpha = (1.0 - pTime).clamp(0.0, 1.0) * 0.45;
      canvas.drawCircle(Offset(dx, dy), r, Paint()..color = Colors.white.withValues(alpha: alpha));
    }

    // Runner Character
    canvas.save();
    canvas.translate(runnerX, runnerY);

    // Dynamic running legs
    final legPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    // Back leg
    canvas.drawLine(const Offset(-2, 10), Offset(-10 - stride * 6, 24), legPaint);
    // Front leg
    canvas.drawLine(const Offset(4, 10), Offset(8 + stride * 6, 24), legPaint);

    // Hoodie Body (Teal)
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      ).createShader(const Rect.fromLTWH(-8, -4, 16, 16));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -4, 16, 16), const Radius.circular(5)), bodyPaint);

    // Head (Peach skin)
    canvas.drawCircle(const Offset(2, -12), 8.5, Paint()..color = const Color(0xFFFFD1A9));

    // Backwards Orange Baseball Cap
    final capPath = Path()
      ..addArc(Rect.fromCircle(center: const Offset(2, -14), radius: 9), math.pi, math.pi)
      ..lineTo(14, -14)
      ..lineTo(-8, -14)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFFF97316));

    // Dynamic swinging arm
    canvas.drawLine(
      const Offset(0, 2),
      Offset(12 - stride * 8, 8),
      Paint()
        ..color = const Color(0xFFFFD1A9)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // Floating Golden Star & Neon Letter Orb overhead
    final starX = (w * 0.75 - (time * 90) % (w * 0.8));
    final starY = h * 0.38 + math.sin(t * 3) * 6.0;
    _drawSparkleStar(canvas, Offset(starX, starY), 7.5, const Color(0xFFFBBF24));
  }

  // =========================================================================
  // 6. CANDY MATCH: 3D jelly candies floating, rotating & shimmering light streak
  // =========================================================================
  void _paintCandy(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    final candies = [
      {'color': const Color(0xFFEF4444), 'pos': Offset(w * 0.28, h * 0.50), 'type': 'heart'},
      {'color': const Color(0xFF3B82F6), 'pos': Offset(w * 0.52, h * 0.42), 'type': 'star'},
      {'color': const Color(0xFFF59E0B), 'pos': Offset(w * 0.74, h * 0.54), 'type': 'circle'},
    ];

    for (int i = 0; i < candies.length; i++) {
      final c = candies[i];
      final basePos = c['pos'] as Offset;
      final color = c['color'] as Color;
      final type = c['type'] as String;

      final bobY = math.sin(t * 2.0 + i * 1.5) * 6.0;
      final pos = Offset(basePos.dx, basePos.dy + bobY);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(math.sin(t * 1.2 + i) * 0.15);

      if (type == 'circle') {
        final r = 16.0;
        final candyPaint = Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 0.9,
            colors: [Colors.white, color, Color.lerp(color, Colors.black, 0.4)!],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
        canvas.drawCircle(Offset.zero, r, candyPaint);
      } else if (type == 'star') {
        _drawSparkleStar(canvas, Offset.zero, 16.0, color);
      } else {
        // Red Heart Candy
        final heartPath = Path()
          ..moveTo(0, 5)
          ..cubicTo(-14, -8, -14, -14, 0, -5)
          ..cubicTo(14, -14, 14, -8, 0, 5)
          ..close();
        canvas.drawPath(
          heartPath,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 0.9,
              colors: [const Color(0xFFFCA5A5), color, const Color(0xFF991B1B)],
            ).createShader(heartPath.getBounds()),
        );
      }

      // Shimmering Star Sparkle Glint
      if ((time * 3 + i).floor() % 3 == 0) {
        _drawSparkleStar(canvas, const Offset(6, -6), 4.5, Colors.white);
      }

      canvas.restore();
    }
  }

  // =========================================================================
  // 7. FISHING: Swimming fish, tail wagging, rising air bubbles & water ripples
  // =========================================================================
  void _paintFishing(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    // Water Surface Curves
    final wavePath = Path()..moveTo(0, h * 0.25);
    for (double x = 0; x <= w; x += 20) {
      wavePath.lineTo(x, h * 0.25 + math.sin((x / 30) + t * 2.5) * 4);
    }
    wavePath.lineTo(w, h);
    wavePath.lineTo(0, h);
    wavePath.close();
    canvas.drawPath(
      wavePath,
      Paint()..color = const Color(0xFF0284C7).withValues(alpha: 0.35),
    );

    // Rising Air Bubbles
    for (int b = 0; b < 5; b++) {
      final bTime = (time * 2.5 + b * 0.2) % 1.0;
      final bx = w * 0.20 + b * 26.0 + math.sin(bTime * 10) * 4;
      final by = h * 0.85 - bTime * h * 0.60;
      final br = 2.0 + (b % 3) * 1.5;
      canvas.drawCircle(
        Offset(bx, by),
        br,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Swimming Cartoon Clownfish
    final fishX = ((time * 65.0) % (w + 60)) - 30;
    final fishY = h * 0.55 + math.sin(t * 2.0) * 7.0;
    final tailWag = math.sin(t * 9.0) * 0.35;

    canvas.save();
    canvas.translate(fishX, fishY);

    // Tail Fin
    final tailPath = Path()
      ..moveTo(-12, 0)
      ..lineTo(-24, -8 + tailWag * 10)
      ..lineTo(-20, 0)
      ..lineTo(-24, 8 + tailWag * 10)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = const Color(0xFFEA580C));

    // Fish Body (Orange)
    final fishRect = Rect.fromCenter(center: Offset.zero, width: 26, height: 18);
    canvas.drawOval(fishRect, Paint()..color = const Color(0xFFF97316));

    // White Stripe
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(-2, 0), width: 4.5, height: 17),
      Paint()..color = Colors.white,
    );

    // Friendly Fish Eye
    canvas.drawCircle(const Offset(6, -3), 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(7, -3), 1.8, Paint()..color = Colors.black87);

    canvas.restore();

    // Fishing Hook dangling
    final hookX = w * 0.65;
    final hookY = h * 0.45 + math.sin(t * 1.5) * 5.0;
    canvas.drawLine(
      Offset(hookX, 0),
      Offset(hookX, hookY),
      Paint()
        ..color = Colors.white60
        ..strokeWidth = 1.2,
    );
    _drawSparkleStar(canvas, Offset(hookX, hookY + 4), 5.0, const Color(0xFFFBBF24));
  }

  // =========================================================================
  // 8. LETTER BASKET: Woven basket swaying, falling ripe apples & stars
  // =========================================================================
  void _paintBasket(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    // Basket at bottom
    final basketSway = math.sin(t * 1.8) * 6.0;
    final basketX = w * 0.50 + basketSway;
    final basketY = h * 0.72;

    // Falling Apples
    for (int i = 0; i < 2; i++) {
      final aTime = (time * 1.8 + i * 0.5) % 1.0;
      final ax = basketX - 12.0 + i * 24.0 + math.sin(aTime * 6) * 4;
      final ay = h * 0.20 + aTime * (basketY - h * 0.20);
      final ar = 10.0;

      // Red Apple
      canvas.drawCircle(Offset(ax, ay), ar, Paint()..color = const Color(0xFFEF4444));
      // Green Leaf
      canvas.drawCircle(Offset(ax + 2, ay - 11), 3.0, Paint()..color = const Color(0xFF22C55E));
    }

    // Wooden Woven Basket
    final basketPath = Path()
      ..moveTo(basketX - 22, basketY)
      ..lineTo(basketX + 22, basketY)
      ..lineTo(basketX + 16, basketY + 18)
      ..lineTo(basketX - 16, basketY + 18)
      ..close();
    canvas.drawPath(
      basketPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB45309), Color(0xFF78350F)],
        ).createShader(basketPath.getBounds()),
    );
    // Basket Handle
    canvas.drawArc(
      Rect.fromCenter(center: Offset(basketX, basketY), width: 36, height: 26),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Stars sparkling from basket
    _drawSparkleStar(canvas, Offset(basketX + 12, basketY - 4), 4.5, const Color(0xFFFBBF24));
  }

  // =========================================================================
  // 9. WORD PUZZLE: Interlocking puzzle tiles sliding and glowing stars
  // =========================================================================
  void _paintPuzzle(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    final puzzleSlide = (math.sin(t * 2.0).abs()) * 8.0;

    // Left Piece
    final leftRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.34 - puzzleSlide, h * 0.44, 22, 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(leftRect, Paint()..color = const Color(0xFF8B5CF6));

    // Right Piece
    final rightRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.52 + puzzleSlide, h * 0.44, 22, 22),
      const Radius.circular(5),
    );
    canvas.drawRRect(rightRect, Paint()..color = const Color(0xFFEC4899));

    // Golden Sparkle
    _drawSparkleStar(canvas, Offset(w * 0.50, h * 0.44), 6.0, const Color(0xFFFBBF24));
  }

  // =========================================================================
  // 10. LETTER MATCHING: Two letter cards drifting together with a sparkle
  // =========================================================================
  void _paintMatching(Canvas canvas, Size size) {
    final t = time * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    final slide = math.sin(t * 2.0).abs() * 6.0;

    void drawCard(Offset topLeft, String label, Color color) {
      final rect = RRect.fromRectAndRadius(
        topLeft & const Size(30, 38),
        const Radius.circular(7),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, topLeft + Offset(15 - text.width / 2, 19 - text.height / 2));
    }

    drawCard(Offset(w * 0.20 + slide, h * 0.30), 'A', const Color(0xFF7C3AED));
    drawCard(Offset(w * 0.80 - 30 - slide, h * 0.30), 'a', const Color(0xFFEC4899));

    _drawSparkleStar(canvas, Offset(w * 0.50, h * 0.30), 6.0, const Color(0xFFFBBF24));
  }

  @override
  bool shouldRepaint(covariant _GameCardArtPainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.gameType != gameType;
}

