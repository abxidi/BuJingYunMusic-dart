import 'package:flutter/material.dart';

import '../../../core/models/ui_style.dart';

class PlayerThemeTokens {
  const PlayerThemeTokens({
    required this.rootStart,
    required this.rootCenter,
    required this.rootEnd,
    required this.panelFill,
    required this.panelStrongFill,
    required this.activeFill,
    required this.line,
    required this.accent,
    required this.accentAlt,
    required this.ink,
    required this.soft,
    required this.muted,
  });

  final Color rootStart;
  final Color rootCenter;
  final Color rootEnd;
  final Color panelFill;
  final Color panelStrongFill;
  final Color activeFill;
  final Color line;
  final Color accent;
  final Color accentAlt;
  final Color ink;
  final Color soft;
  final Color muted;

  static PlayerThemeTokens fromStyle(UiStyle style) {
    if (style == UiStyle.radar) {
      return const PlayerThemeTokens(
        rootStart: Color.fromARGB(255, 2, 19, 16),
        rootCenter: Color.fromARGB(255, 4, 42, 32),
        rootEnd: Color.fromARGB(255, 1, 8, 9),
        panelFill: Color.fromARGB(240, 5, 44, 34),
        panelStrongFill: Color.fromARGB(248, 4, 56, 43),
        activeFill: Color.fromARGB(86, 78, 255, 177),
        line: Color.fromARGB(185, 86, 255, 190),
        accent: Color.fromARGB(255, 90, 255, 187),
        accentAlt: Color.fromARGB(255, 202, 255, 85),
        ink: Color(0xFFEEF8FF),
        soft: Color(0xB8EEF8FF),
        muted: Color(0xFF8DA3B7),
      );
    }

    if (style == UiStyle.galaxy) {
      return const PlayerThemeTokens(
        rootStart: Color.fromARGB(255, 1, 1, 2),
        rootCenter: Color.fromARGB(255, 13, 14, 17),
        rootEnd: Color.fromARGB(255, 0, 0, 0),
        panelFill: Color.fromARGB(242, 14, 15, 18),
        panelStrongFill: Color.fromARGB(250, 24, 25, 29),
        activeFill: Color.fromARGB(96, 245, 247, 250),
        line: Color.fromARGB(172, 214, 218, 224),
        accent: Color.fromARGB(255, 245, 247, 250),
        accentAlt: Color.fromARGB(255, 142, 148, 158),
        ink: Color(0xFFEEF8FF),
        soft: Color(0xB8EEF8FF),
        muted: Color(0xFF8DA3B7),
      );
    }

    return const PlayerThemeTokens(
      rootStart: Color(0xFF04070D),
      rootCenter: Color(0xFF0A1220),
      rootEnd: Color(0xFF04070D),
      panelFill: Color(0xCC0A1220),
      panelStrongFill: Color(0xF20F192A),
      activeFill: Color(0x3D72E6FF),
      line: Color(0x3D72E6FF),
      accent: Color(0xFF64E8FF),
      accentAlt: Color(0xFF6DFFBF),
      ink: Color(0xFFEEF8FF),
      soft: Color(0xB8EEF8FF),
      muted: Color(0xFF8DA3B7),
    );
  }

  BoxDecoration rootDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [rootStart, rootCenter, rootEnd],
      ),
    );
  }

  BoxDecoration panelDecoration({bool strong = false}) {
    final fill = strong ? panelStrongFill : panelFill;
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: accent.withAlpha(strong ? 242 : 191)),
    );
  }

  BoxDecoration controlDecoration({bool active = false}) {
    return BoxDecoration(
      color: active ? activeFill : panelFill,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: active ? accent : line.withAlpha(179)),
    );
  }

  BoxDecoration desktopPanelDecoration({bool strong = false}) {
    final fill = strong ? panelStrongFill : panelFill;
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: line.withAlpha(strong ? 220 : 150)),
    );
  }

  BoxDecoration desktopControlDecoration({bool active = false}) {
    return BoxDecoration(
      color: active ? activeFill : panelFill,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: active ? accent : line.withAlpha(150)),
    );
  }

  BoxDecoration playDecoration({double radius = 24}) {
    return BoxDecoration(
      gradient: LinearGradient(colors: [accent, accentAlt]),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}
