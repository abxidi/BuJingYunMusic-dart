# 步惊云音乐 Flutter 迁移状态

生成时间：2026-06-20

## 已迁移能力

| 原 Android 能力 | Flutter/Dart 落点 |
| --- | --- |
| 本地音频播放 | `lib/features/player/application/bujingyun_audio_handler.dart` 使用 `just_audio` |
| 后台播放通知、系统媒体控制 | `audio_service` 初始化与 `android/app/src/main/AndroidManifest.xml` 服务声明 |
| 音频焦点/中断处理 | `audio_session` 音乐会话配置 |
| 系统曲库扫描 | Android `android/app/src/main/java/com/novapulse/mp3/MainActivity.java` 的 `scanAudioStore`；macOS `macos/Runner/MainFlutterWindow.swift` 的 `scanAudioStore` |
| Android 13+ / 旧版音频权限 | Android Manifest 与 `audioPermission()` |
| 选择目录递归扫描 | Android `ACTION_OPEN_DOCUMENT_TREE` + `DocumentsContract`；macOS `NSOpenPanel` + 目录递归扫描 |
| 支持音频扩展名兜底 | Android `AUDIO_EXTENSIONS` |
| 播放/暂停/上一首/下一首/进度拖动 | `PlayerScreen` + `PlaybackController` |
| 随机、列表循环、单曲循环 | `PlaybackQueueController` |
| 收藏/取消收藏 | `FavoritesController` |
| 收藏持久化和旧 key 兼容 | `favorite_keys.dart` + `PreferencesStore` |
| 全部音乐/收藏音乐面板 | `PlayerScreen` 的 `_PlaylistPanel` |
| 收藏队列优先切歌 | `PlaybackQueueController.activateFavoriteQueue` |
| 霓虹、波纹、雷达三套视觉 | `visualizer_widgets.dart` + `player_theme.dart` |
| 启动 sample 列表 | `sample_songs.dart` |
| 设置面板目录选择、主题切换 | `PlayerScreen` 的 `_showSettings` |

## macOS 迁移状态

已生成标准 Flutter macOS 平台目录 `macos/`，并注册同名平台通道 `com.novapulse.mp3/music_library`：

- `scanAudioStore`：默认扫描当前用户的 `~/Music`。
- `pickAndScanFolder`：通过 `NSOpenPanel` 选择目录后递归扫描音频文件。
- 返回 `file://` URI，供 `just_audio` 在 macOS 侧播放。
- macOS entitlements 已加入用户选择目录只读权限。

## 未新增能力

未加入歌词、在线音乐源、云同步、自定义歌单、最近播放、封面解析等原工程未实现能力。

## 当前验证限制

当前环境的 Flutter SDK 位于 `.flutter-sdk`，Dart 静态分析已通过：

```bash
flutter analyze
```

仍未完成的验证：

- `flutter test`：当前沙箱禁止 Flutter tester 绑定本地 `127.0.0.1` 临时端口。
- `flutter build apk --debug`：当前沙箱禁止 Gradle 文件锁 socket。
- `flutter build macos --debug`：当前环境缺少完整 Xcode，且 Flutter 还需要下载 macOS engine framework。
