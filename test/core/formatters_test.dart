import 'package:flutter_test/flutter_test.dart';
import 'package:bujingyun_music/core/utils/formatters.dart';

void main() {
  test('duration formatting matches Android mm:ss behavior', () {
    expect(formatDurationMs(0), '00:00');
    expect(formatDurationMs(228000), '03:48');
    expect(formatDurationMs(3661000), '61:01');
  });

  test('size formatting matches Android one decimal MB behavior', () {
    expect(formatSizeBytes(0), '未知大小');
    expect(formatSizeBytes(9017753), '8.6 MB');
  });
}
