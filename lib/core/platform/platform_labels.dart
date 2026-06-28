import 'dart:io';

String get defaultMusicFolderLabel {
  if (Platform.isMacOS) {
    return '~/Music';
  }
  return '/storage/emulated/0/Music';
}

String get platformMusicFolderLabel {
  if (Platform.isMacOS) {
    return 'Mac / Music';
  }
  return '手机存储 / Music';
}

String get sampleMusicMetaPrefix {
  if (Platform.isMacOS) {
    return 'Mac / Music';
  }
  return '手机存储 / Music';
}

String get chooseMusicFolderLabel {
  if (Platform.isMacOS) {
    return '选择 Mac 音乐目录';
  }
  return '选择手机存储目录';
}

String get playbackUnavailableMessage {
  if (Platform.isMacOS) {
    return '选择本机音频目录后可播放真实音频';
  }
  return '授权后可播放手机中的真实音频';
}
