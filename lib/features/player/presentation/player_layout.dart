import 'package:flutter/foundation.dart';

enum PlayerLayoutKind {
  mobile,
  desktop,
}

const double desktopPlayerBreakpoint = 1000;

PlayerLayoutKind playerLayoutKindFor({
  required TargetPlatform platform,
  required double width,
}) {
  if (platform == TargetPlatform.macOS ||
      platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux) {
    return PlayerLayoutKind.desktop;
  }

  if (width >= desktopPlayerBreakpoint) {
    return PlayerLayoutKind.desktop;
  }

  return PlayerLayoutKind.mobile;
}
