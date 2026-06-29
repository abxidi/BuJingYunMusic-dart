import 'package:bujingyun_music/features/player/presentation/player_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS and wide windows use desktop player layout', () {
    expect(
      playerLayoutKindFor(platform: TargetPlatform.macOS, width: 720),
      PlayerLayoutKind.desktop,
    );
    expect(
      playerLayoutKindFor(platform: TargetPlatform.android, width: 1120),
      PlayerLayoutKind.desktop,
    );
  });

  test('phone-sized non-desktop windows keep the mobile player layout', () {
    expect(
      playerLayoutKindFor(platform: TargetPlatform.android, width: 430),
      PlayerLayoutKind.mobile,
    );
  });
}
