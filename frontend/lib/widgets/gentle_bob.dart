import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Gives a still character image a light, looping "alive" motion:
/// a soft float up and down, a tiny side-to-side sway and a gentle breathe.
///
/// [phase] (0–1) offsets the cycle so several images on one screen
/// don't move in perfect sync.
class GentleBob extends StatefulWidget {
  final Widget child;
  final double phase;
  final double floatHeight;
  final double swayDegrees;
  final Duration period;

  const GentleBob({
    super.key,
    required this.child,
    this.phase = 0,
    this.floatHeight = 4,
    this.swayDegrees = 3,
    this.period = const Duration(milliseconds: 2400),
  });

  @override
  State<GentleBob> createState() => _GentleBobState();
}

class _GentleBobState extends State<GentleBob> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..value = widget.phase.clamp(0.0, 1.0)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect the system "reduce motion" setting.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        final dy = -math.sin(t).abs() * widget.floatHeight; // little hop, lands softly
        final angle = math.sin(t) * widget.swayDegrees * math.pi / 180; // tiny side sway
        final scale = 1 + math.sin(t * 2) * 0.02; // gentle breathe
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomCenter,
            child: Transform.scale(scale: scale, alignment: Alignment.bottomCenter, child: child),
          ),
        );
      },
    );
  }
}
