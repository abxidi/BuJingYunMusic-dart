enum UiStyle {
  classic(0, '霓虹'),
  galaxy(2, '波纹'),
  radar(3, '雷达');

  const UiStyle(this.androidValue, this.label);

  final int androidValue;
  final String label;

  static UiStyle fromStoredValue(int value) {
    return switch (value) {
      2 => UiStyle.galaxy,
      3 => UiStyle.radar,
      _ => UiStyle.classic,
    };
  }
}
