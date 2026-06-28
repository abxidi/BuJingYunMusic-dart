import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/models/ui_style.dart';
import '../../player/presentation/player_theme.dart';

class ThemeVisualizer extends StatefulWidget {
  const ThemeVisualizer({
    required this.style,
    required this.playing,
    required this.tokens,
    super.key,
  });

  final UiStyle style;
  final bool playing;
  final PlayerThemeTokens tokens;

  @override
  State<ThemeVisualizer> createState() => _ThemeVisualizerState();
}

class _ThemeVisualizerState extends State<ThemeVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == UiStyle.classic) {
      return ClassicDisc(playing: widget.playing, tokens: widget.tokens);
    }
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: widget.style == UiStyle.radar
                ? RadarPainter(
                    phase: _controller.value,
                    playing: widget.playing,
                    tokens: widget.tokens,
                  )
                : GalaxyPainter(
                    phase: _controller.value,
                    playing: widget.playing,
                    tokens: widget.tokens,
                  ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class ClassicDisc extends StatefulWidget {
  const ClassicDisc({
    required this.playing,
    required this.tokens,
    super.key,
  });

  final bool playing;
  final PlayerThemeTokens tokens;

  @override
  State<ClassicDisc> createState() => _ClassicDiscState();
}

class _ClassicDiscState extends State<ClassicDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    if (widget.playing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ClassicDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              widget.tokens.accentAlt,
              const Color(0xFF111827),
              const Color(0xFF020617),
            ],
            stops: const [0.03, 0.18, 1],
          ),
          border: Border.all(color: widget.tokens.line, width: 2),
          boxShadow: [
            BoxShadow(
              color: widget.tokens.accent.withAlpha(72),
              blurRadius: 34,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF04070D),
              border: Border.all(color: widget.tokens.accent, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class GalaxyPainter extends CustomPainter {
  GalaxyPainter({
    required this.phase,
    required this.playing,
    required this.tokens,
  });

  final double phase;
  final bool playing;
  final PlayerThemeTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .38;
    final paint = Paint()..isAntiAlias = true;
    final beat = _wave(phase * (playing ? 14 : 4));

    paint.shader = RadialGradient(
      colors: [
        tokens.accent.withAlpha((30 + 34 * beat).round()),
        tokens.accentAlt.withAlpha(26),
        Colors.transparent,
      ],
      stops: const [0, .45, 1],
    ).createShader(Rect.fromCircle(center: center, radius: radius * 1.25));
    canvas.drawCircle(center, radius, paint);
    paint.shader = null;

    final dotGap = radius * .08;
    for (var y = -radius; y <= radius; y += dotGap) {
      for (var x = -radius; x <= radius; x += dotGap) {
        final distance = math.sqrt(x * x + y * y);
        if (distance > radius || distance < radius * .04) {
          continue;
        }
        final wave = _wave(distance / radius * 18 - phase * (playing ? 30 : 9));
        final alpha = (28 + 170 * wave * (playing ? 1 : .55)).round();
        paint.color = tokens.accent.withAlpha(alpha.clamp(0, 220).toInt());
        canvas.drawCircle(
          center + Offset(x, y),
          radius * (.006 + .008 * wave),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GalaxyPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.playing != playing ||
        oldDelegate.tokens != tokens;
  }
}

class RadarPainter extends CustomPainter {
  RadarPainter({
    required this.phase,
    required this.playing,
    required this.tokens,
  });

  final double phase;
  final bool playing;
  final PlayerThemeTokens tokens;

  static const _notes = ['♪', '♫', '♬', '♩', '♭'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .38;
    final paint = Paint()..isAntiAlias = true;
    final sweep = phase * math.pi * 2 * (playing ? 1 : .28);

    paint.shader = RadialGradient(
      colors: [
        tokens.accent.withAlpha(92),
        tokens.accent.withAlpha(36),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius * 1.18));
    canvas.drawCircle(center, radius, paint);
    paint.shader = null;

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = tokens.accent.withAlpha(130);
    for (var ring = 1; ring <= 4; ring += 1) {
      canvas.drawCircle(center, radius * ring / 4, paint);
    }
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );

    for (var tick = 0; tick < 72; tick += 1) {
      final angle = tick * math.pi / 36;
      final inner = radius * (tick % 6 == 0 ? .9 : .955);
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        paint,
      );
    }

    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = tokens.accent.withAlpha(88);
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        sweep - .7,
        .7,
        false,
      )
      ..close();
    canvas.drawPath(path, sweepPaint);

    final linePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5
      ..color = tokens.accent.withAlpha(210);
    canvas.drawLine(
      center,
      center + Offset(math.cos(sweep) * radius, math.sin(sweep) * radius),
      linePaint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    for (var index = 0; index < 20; index += 1) {
      final angle = index * 1.721 + phase * (playing ? .7 : .18);
      final noteRadius = radius * (.18 + (index * 37 % 76) / 100);
      final point = center +
          Offset(
            math.cos(angle) * noteRadius,
            math.sin(angle) * noteRadius,
          );
      textPainter.text = TextSpan(
        text: _notes[index % _notes.length],
        style: TextStyle(
          color: tokens.ink.withAlpha(120 + (index * 19 % 120)),
          fontSize: 12 + (index % 4) * 2,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        point - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    textPainter.text = TextSpan(
      text: 'RADAR\nAUDIO SCAN',
      style: TextStyle(
        color: tokens.accentAlt.withAlpha(170),
        fontSize: 12,
        height: 1.8,
        fontWeight: FontWeight.w700,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.phase != phase ||
        oldDelegate.playing != playing ||
        oldDelegate.tokens != tokens;
  }
}

double _wave(double value) {
  return (math.sin(value) + 1) / 2;
}
