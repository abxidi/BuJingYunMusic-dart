# macOS 构建与运行验证记录

验证日期：2026-06-28

## 当前结论

当前工程的 Flutter/Dart 代码静态检查和单元测试通过，CocoaPods 已安装，Flutter macOS engine/framework 产物已完成预缓存，完整 Xcode 已安装，`flutter build macos --debug` 与 `flutter run -d macos` 均已完成验证。

## 已验证通过

```bash
env HOME=/Users/liutengfei24/workspace/ai_idea/dart/.home \
  PUB_HOSTED_URL=https://pub.flutter-io.cn \
  ./.flutter-sdk/bin/flutter analyze
```

结果：

```text
No issues found!
```

```bash
env HOME=/Users/liutengfei24/workspace/ai_idea/dart/.home \
  PUB_HOSTED_URL=https://pub.flutter-io.cn \
  FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git \
  ./.flutter-sdk/bin/flutter test
```

结果：

```text
All tests passed!
```

已通过 `flutter precache --macos` 完成 macOS engine/framework 预缓存，当前缓存中已存在：

```text
.flutter-sdk/bin/cache/artifacts/engine/darwin-x64/FlutterMacOS.xcframework
.flutter-sdk/bin/cache/artifacts/engine/darwin-x64-profile/FlutterMacOS.xcframework
.flutter-sdk/bin/cache/artifacts/engine/darwin-x64-release/FlutterMacOS.xcframework
```

```bash
env HOME=/Users/liutengfei24/workspace/ai_idea/dart/.home \
  PUB_HOSTED_URL=https://pub.flutter-io.cn \
  FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git \
  ./.flutter-sdk/bin/flutter build macos --debug
```

结果：

```text
✓ Built build/macos/Build/Products/Debug/bujingyun_music.app
```

```bash
env HOME=/Users/liutengfei24/workspace/ai_idea/dart/.home \
  PUB_HOSTED_URL=https://pub.flutter-io.cn \
  FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git \
  ./.flutter-sdk/bin/flutter run -d macos
```

结果：

```text
Launching lib/main.dart on macOS in debug mode...
✓ Built build/macos/Build/Products/Debug/bujingyun_music.app
A Dart VM Service on macOS is available at: http://127.0.0.1:63514/...
Application finished.
```

运行验证期间曾暴露两个小窗口布局溢出，已在 `lib/features/player/presentation/player_screen.dart` 修复：

- 主播放器 `Column` 在 macOS 初始窗口高度下溢出。
- 底部 `_PanelShell` 面板内容在受限高度下溢出。

## 当前环境状态

- Flutter SDK：工程内 `.flutter-sdk`，版本 `3.44.2`。
- Android toolchain：本次 macOS 验证不依赖 Android 构建链。
- macOS 平台代码：`macos/` 已存在，`MainFlutterWindow.swift` 已注册 `com.novapulse.mp3/music_library` 平台通道。
- Xcode：当前 `xcode-select -p` 指向 `/Applications/Xcode.app/Contents/Developer`，`xcodebuild -version` 为 `Xcode 26.6` / `Build version 17F113`。
- CocoaPods：已通过 Homebrew 安装，`pod --version` 为 `1.16.2`。
- Flutter macOS framework：已通过 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` 完成预缓存。

## 复跑命令

在工程目录执行：

```bash
env HOME=/Users/liutengfei24/workspace/ai_idea/dart/.home \
  PUB_HOSTED_URL=https://pub.flutter-io.cn \
  FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git \
  ./.flutter-sdk/bin/flutter doctor -v

env HOME=/Users/liutengfei24/workspace/ai_idea/dart/.home \
  PUB_HOSTED_URL=https://pub.flutter-io.cn \
  FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git \
  ./.flutter-sdk/bin/flutter build macos --debug

env HOME=/Users/liutengfei24/workspace/ai_idea/dart/.home \
  PUB_HOSTED_URL=https://pub.flutter-io.cn \
  FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn \
  FLUTTER_GIT_URL=https://gitee.com/mirrors/Flutter.git \
  ./.flutter-sdk/bin/flutter run -d macos
```
