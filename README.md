# 步惊云音乐

Flutter 迁移版本地音乐播放器，当前支持 Android 与 macOS 目标。

## 平台能力

- Android：通过 MediaStore 扫描本地音频，支持选择目录递归扫描。
- macOS：默认扫描 `~/Music`，支持通过系统目录选择器扫描本地音频。
- 播放：使用 `just_audio` 与 `audio_service`。
- 状态管理：使用 Riverpod。

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test
flutter build macos --debug
flutter build apk --debug
```

本地工作目录内带有 `.flutter-sdk` 时，可直接使用：

```bash
./.flutter-sdk/bin/flutter analyze
```
