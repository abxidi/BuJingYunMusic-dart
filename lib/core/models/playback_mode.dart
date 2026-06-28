enum PlaybackMode {
  shuffle,
  repeatAll,
  repeatOne;

  PlaybackMode get next {
    return values[(index + 1) % values.length];
  }

  String get label {
    return switch (this) {
      PlaybackMode.shuffle => '随机播放',
      PlaybackMode.repeatAll => '循环播放',
      PlaybackMode.repeatOne => '单曲循环',
    };
  }
}
