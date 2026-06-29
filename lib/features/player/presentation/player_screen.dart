import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../app/app_providers.dart';
import '../../../core/models/playback_mode.dart';
import '../../../core/models/song.dart';
import '../../../core/models/ui_style.dart';
import '../../../core/platform/platform_labels.dart';
import '../../../core/utils/formatters.dart';
import '../../visualizer/presentation/visualizer_widgets.dart';
import '../application/bujingyun_audio_handler.dart';
import '../application/playback_view_state.dart';
import '../../library/application/library_state.dart';
import 'player_layout.dart';
import 'player_theme.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    final playback = ref.watch(playbackControllerProvider);
    final playbackController = ref.read(playbackControllerProvider.notifier);
    final audioHandler = ref.watch(audioHandlerProvider);
    final tokens = PlayerThemeTokens.fromStyle(playback.uiStyle);
    final songs = library.songs;
    final currentIndex = songs.isEmpty
        ? 0
        : playback.currentIndex.clamp(0, songs.length - 1).toInt();
    final currentSong = songs.isEmpty ? null : songs[currentIndex];

    ref.listen(playbackControllerProvider, (previous, next) {
      final message = next.lastMessage;
      if (message != null && message != previous?.lastMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
    ref.listen(libraryControllerProvider, (previous, next) {
      final finishedScan = previous?.loading == true &&
          !next.loading &&
          !next.message.startsWith('已删除') &&
          next.message != '当前曲库为空';
      if (finishedScan) {
        unawaited(playbackController.restoreSelection(next.songs));
      }
    });

    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data ?? PlaybackState();
        final playing = playbackState.playing;
        void openSettings() => _showAdaptiveSettings(context, ref, tokens);
        void chooseFolder() => unawaited(
              ref.read(libraryControllerProvider.notifier).pickAndScanFolder(),
            );
        void togglePlay() => unawaited(
              playbackController.togglePlay(songs, playbackState),
            );
        void playPrevious() => unawaited(
              playbackController.playPrevious(songs: songs),
            );
        void playNext() => unawaited(
              playbackController.playNext(manual: true, songs: songs),
            );

        final player = Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: tokens.rootDecoration(),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final layoutKind = playerLayoutKindFor(
                    platform: Theme.of(context).platform,
                    width: constraints.maxWidth,
                  );
                  if (layoutKind == PlayerLayoutKind.desktop) {
                    return _DesktopPlayerLayout(
                      library: library,
                      playback: playback,
                      tokens: tokens,
                      songs: songs,
                      currentIndex: currentIndex,
                      currentSong: currentSong,
                      playing: playing,
                      audioHandler: audioHandler,
                      playbackState: playbackState,
                      onSettings: openSettings,
                      onChooseFolder: chooseFolder,
                      onDeleteCurrent: currentSong == null
                          ? null
                          : () => _confirmDeleteCurrentSong(
                                context,
                                ref,
                                currentIndex,
                                playing,
                              ),
                    );
                  }

                  final height = constraints.maxHeight;
                  final compact = height < 650;
                  final visualizerSize = math
                      .min(
                        MediaQuery.sizeOf(context)
                            .shortestSide
                            .clamp(220, 328)
                            .toDouble(),
                        (height * (compact ? .30 : .40)).clamp(160, 328),
                      )
                      .toDouble();
                  final topGap = compact ? 12.0 : 28.0;
                  final titleGap = compact ? 14.0 : 28.0;
                  final barsGap = compact ? 12.0 : 24.0;
                  final progressGap = compact ? 10.0 : 22.0;
                  final controlGap = compact ? 10.0 : 26.0;

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TopBar(
                              tokens: tokens,
                              onSettings: openSettings,
                            ),
                            SizedBox(height: topGap),
                            SizedBox.square(
                              dimension: visualizerSize,
                              child: ThemeVisualizer(
                                style: playback.uiStyle,
                                playing: playing,
                                tokens: tokens,
                              ),
                            ),
                            SizedBox(height: titleGap),
                            _TrackHeader(
                              song: currentSong,
                              tokens: tokens,
                              onDelete: currentSong == null
                                  ? null
                                  : () => _confirmDeleteCurrentSong(
                                        context,
                                        ref,
                                        currentIndex,
                                        playing,
                                      ),
                              onFavorite: currentSong == null
                                  ? null
                                  : () async {
                                      await ref
                                          .read(
                                            libraryControllerProvider.notifier,
                                          )
                                          .toggleFavorite(currentIndex);
                                      playbackController.refreshFavoriteQueue(
                                        ref
                                            .read(libraryControllerProvider)
                                            .songs,
                                      );
                                    },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentSong?.meta ??
                                  '$sampleMusicMetaPrefix / Synthwave',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: tokens.soft,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: barsGap),
                            _MiniBars(playing: playing, tokens: tokens),
                            SizedBox(height: progressGap),
                            _ProgressRow(
                              tokens: tokens,
                              audioHandler: audioHandler,
                            ),
                            SizedBox(height: controlGap),
                            _ControlRow(
                              tokens: tokens,
                              mode: playback.mode,
                              playing: playing,
                              onMode: playbackController.switchMode,
                              onPrevious: playPrevious,
                              onPlay: togglePlay,
                              onNext: playNext,
                              onPlaylist: () => _showPlaylist(
                                context,
                                ref,
                                tokens,
                                favorites: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        final commandScope = _PlayerCommandScope(
          onOpenSettings: openSettings,
          onChooseFolder: chooseFolder,
          onTogglePlay: togglePlay,
          onPrevious: playPrevious,
          onNext: playNext,
          child: player,
        );
        if (Theme.of(context).platform == TargetPlatform.macOS) {
          return _PlayerMenuBar(
            onOpenSettings: openSettings,
            onChooseFolder: chooseFolder,
            onTogglePlay: togglePlay,
            onPrevious: playPrevious,
            onNext: playNext,
            child: commandScope,
          );
        }
        return commandScope;
      },
    );
  }

  Future<void> _showAdaptiveSettings(
    BuildContext context,
    WidgetRef ref,
    PlayerThemeTokens tokens,
  ) {
    final layoutKind = playerLayoutKindFor(
      platform: Theme.of(context).platform,
      width: MediaQuery.sizeOf(context).width,
    );
    if (layoutKind == PlayerLayoutKind.desktop) {
      return _showDesktopSettings(context, ref, tokens);
    }
    return _showSettings(context, ref, tokens);
  }

  Future<void> _showDesktopSettings(
    BuildContext context,
    WidgetRef ref,
    PlayerThemeTokens tokens,
  ) {
    final library = ref.read(libraryControllerProvider);
    final playback = ref.read(playbackControllerProvider);
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: tokens.desktopPanelDecoration(strong: true),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '设置',
                            style: TextStyle(
                              color: tokens.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _DesktopIconButton(
                          tokens: tokens,
                          icon: Icons.close,
                          label: '关闭',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DesktopFolderSummary(tokens: tokens, library: library),
                    const SizedBox(height: 16),
                    _DesktopPrimaryButton(
                      tokens: tokens,
                      icon: Icons.folder_open,
                      label: chooseMusicFolderLabel,
                      onPressed: () {
                        Navigator.pop(context);
                        ref
                            .read(libraryControllerProvider.notifier)
                            .pickAndScanFolder();
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'UI 样式',
                      style: TextStyle(color: tokens.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    _DesktopStyleSelector(
                      tokens: tokens,
                      playback: playback,
                      onSelected: (style) => ref
                          .read(playbackControllerProvider.notifier)
                          .setUiStyle(style),
                    ),
                    const SizedBox(height: 18),
                    _DesktopSettingStatus(tokens: tokens, label: '启动自动扫描'),
                    _DesktopSettingStatus(tokens: tokens, label: '默认播放收藏队列'),
                    _DesktopSettingStatus(tokens: tokens, label: '暗场动态频谱'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSettings(
    BuildContext context,
    WidgetRef ref,
    PlayerThemeTokens tokens,
  ) {
    final library = ref.read(libraryControllerProvider);
    final playback = ref.read(playbackControllerProvider);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PanelShell(
          tokens: tokens,
          title: '设置',
          subtitle: '目录 / 播放控制',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FolderSummary(tokens: tokens, library: library),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: DecoratedBox(
                  decoration: tokens.playDecoration(),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref
                          .read(libraryControllerProvider.notifier)
                          .pickAndScanFolder();
                    },
                    child: Text(
                      chooseMusicFolderLabel,
                      style: const TextStyle(
                        color: Color(0xFF041218),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('启动自动扫描', style: TextStyle(color: tokens.ink)),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('默认播放收藏队列', style: TextStyle(color: tokens.ink)),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('暗场动态频谱', style: TextStyle(color: tokens.ink)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'UI 样式',
                  style: TextStyle(color: tokens.muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: UiStyle.values.map((style) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _TextChipButton(
                        label: style.label,
                        active: playback.uiStyle == style,
                        tokens: tokens,
                        onTap: () => ref
                            .read(playbackControllerProvider.notifier)
                            .setUiStyle(style),
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteCurrentSong(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
    bool wasPlaying,
  ) async {
    final song = ref.read(libraryControllerProvider).songs[currentIndex];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final tokens = PlayerThemeTokens.fromStyle(
          ref.read(playbackControllerProvider).uiStyle,
        );
        return AlertDialog(
          backgroundColor: tokens.panelStrongFill,
          title: Text('删除当前歌曲', style: TextStyle(color: tokens.ink)),
          content: Text(
            '将从本地目录中彻底删除：\n${song.title}',
            style: TextStyle(color: tokens.soft),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消', style: TextStyle(color: tokens.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                '删除',
                style: TextStyle(color: Color(0xFFFF5D9F)),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final deleted = await ref
        .read(libraryControllerProvider.notifier)
        .deleteSong(currentIndex);
    if (!deleted) {
      return;
    }
    await ref.read(playbackControllerProvider.notifier).removeSongAt(
          deletedIndex: currentIndex,
          songs: ref.read(libraryControllerProvider).songs,
          wasPlaying: wasPlaying,
        );
  }

  Future<void> _showPlaylist(
    BuildContext context,
    WidgetRef ref,
    PlayerThemeTokens tokens, {
    required bool favorites,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PlaylistPanel(
          tokens: tokens,
          initialFavorites: favorites,
        );
      },
    );
  }
}

class _TogglePlayIntent extends Intent {
  const _TogglePlayIntent();
}

class _PreviousTrackIntent extends Intent {
  const _PreviousTrackIntent();
}

class _NextTrackIntent extends Intent {
  const _NextTrackIntent();
}

class _ChooseFolderIntent extends Intent {
  const _ChooseFolderIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _PlayerCommandScope extends StatelessWidget {
  const _PlayerCommandScope({
    required this.onOpenSettings,
    required this.onChooseFolder,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onChooseFolder;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): _TogglePlayIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousTrackIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextTrackIntent(),
        SingleActivator(LogicalKeyboardKey.keyO, meta: true):
            _ChooseFolderIntent(),
        SingleActivator(LogicalKeyboardKey.comma, meta: true):
            _OpenSettingsIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _TogglePlayIntent: CallbackAction<_TogglePlayIntent>(
            onInvoke: (_) {
              onTogglePlay();
              return null;
            },
          ),
          _PreviousTrackIntent: CallbackAction<_PreviousTrackIntent>(
            onInvoke: (_) {
              onPrevious();
              return null;
            },
          ),
          _NextTrackIntent: CallbackAction<_NextTrackIntent>(
            onInvoke: (_) {
              onNext();
              return null;
            },
          ),
          _ChooseFolderIntent: CallbackAction<_ChooseFolderIntent>(
            onInvoke: (_) {
              onChooseFolder();
              return null;
            },
          ),
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              onOpenSettings();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _PlayerMenuBar extends StatelessWidget {
  const _PlayerMenuBar({
    required this.onOpenSettings,
    required this.onChooseFolder,
    required this.onTogglePlay,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onChooseFolder;
  final VoidCallback onTogglePlay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: '文件',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: '选择音乐目录',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyO,
                meta: true,
              ),
              onSelected: onChooseFolder,
            ),
            PlatformMenuItem(
              label: '设置',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.comma,
                meta: true,
              ),
              onSelected: onOpenSettings,
            ),
          ],
        ),
        PlatformMenu(
          label: '播放',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: '播放 / 暂停',
              shortcut: const SingleActivator(LogicalKeyboardKey.space),
              onSelected: onTogglePlay,
            ),
            PlatformMenuItem(
              label: '上一首',
              shortcut: const SingleActivator(LogicalKeyboardKey.arrowLeft),
              onSelected: onPrevious,
            ),
            PlatformMenuItem(
              label: '下一首',
              shortcut: const SingleActivator(LogicalKeyboardKey.arrowRight),
              onSelected: onNext,
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}

class _DesktopPlayerLayout extends ConsumerStatefulWidget {
  const _DesktopPlayerLayout({
    required this.library,
    required this.playback,
    required this.tokens,
    required this.songs,
    required this.currentIndex,
    required this.currentSong,
    required this.playing,
    required this.audioHandler,
    required this.playbackState,
    required this.onSettings,
    required this.onChooseFolder,
    required this.onDeleteCurrent,
  });

  final LibraryState library;
  final PlaybackViewState playback;
  final PlayerThemeTokens tokens;
  final List<Song> songs;
  final int currentIndex;
  final Song? currentSong;
  final bool playing;
  final BujingyunAudioHandler audioHandler;
  final PlaybackState playbackState;
  final VoidCallback onSettings;
  final VoidCallback onChooseFolder;
  final VoidCallback? onDeleteCurrent;

  @override
  ConsumerState<_DesktopPlayerLayout> createState() =>
      _DesktopPlayerLayoutState();
}

class _DesktopPlayerLayoutState extends ConsumerState<_DesktopPlayerLayout> {
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final indices = ref
        .read(libraryControllerProvider.notifier)
        .sortedSongIndices(favoritesOnly: _favoritesOnly);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 230,
            child: _DesktopSidebar(
              library: widget.library,
              playback: widget.playback,
              tokens: widget.tokens,
              onSettings: widget.onSettings,
              onChooseFolder: widget.onChooseFolder,
              onScanDefault: () => unawaited(
                ref.read(libraryControllerProvider.notifier).scanAudioStore(),
              ),
              onStyleSelected: (style) => unawaited(
                ref.read(playbackControllerProvider.notifier).setUiStyle(style),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DesktopNowPlaying(
              tokens: widget.tokens,
              playback: widget.playback,
              song: widget.currentSong,
              playing: widget.playing,
              audioHandler: widget.audioHandler,
              onDeleteCurrent: widget.onDeleteCurrent,
              onFavoriteCurrent: widget.currentSong == null
                  ? null
                  : () => _toggleFavorite(widget.currentIndex),
              onMode: () => unawaited(
                ref.read(playbackControllerProvider.notifier).switchMode(),
              ),
              onPrevious: () => unawaited(
                ref
                    .read(playbackControllerProvider.notifier)
                    .playPrevious(songs: widget.songs),
              ),
              onPlay: () => unawaited(
                ref
                    .read(playbackControllerProvider.notifier)
                    .togglePlay(widget.songs, widget.playbackState),
              ),
              onNext: () => unawaited(
                ref.read(playbackControllerProvider.notifier).playNext(
                      manual: true,
                      songs: widget.songs,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 340,
            child: _DesktopQueuePanel(
              tokens: widget.tokens,
              library: widget.library,
              playback: widget.playback,
              indices: indices,
              favoritesOnly: _favoritesOnly,
              onToggleFavoritesOnly: (value) =>
                  setState(() => _favoritesOnly = value),
              onPlayFirst: indices.isEmpty ? null : () => _playSong(indices[0]),
              onSelectSong: _playSong,
              onFavoriteSong: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playSong(int songIndex) async {
    final controller = ref.read(playbackControllerProvider.notifier);
    if (_favoritesOnly) {
      controller.activateFavoriteQueue(songIndex, widget.library.songs);
      await controller.selectSong(
        songIndex,
        songs: widget.library.songs,
        start: true,
        keepQueue: true,
      );
      return;
    }
    await controller.selectSong(
      songIndex,
      songs: widget.library.songs,
      start: true,
    );
  }

  Future<void> _toggleFavorite(int songIndex) async {
    await ref
        .read(libraryControllerProvider.notifier)
        .toggleFavorite(songIndex);
    ref
        .read(playbackControllerProvider.notifier)
        .refreshFavoriteQueue(ref.read(libraryControllerProvider).songs);
  }
}

class _DesktopPanel extends StatelessWidget {
  const _DesktopPanel({
    required this.tokens,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final PlayerThemeTokens tokens;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: tokens.desktopPanelDecoration(),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.library,
    required this.playback,
    required this.tokens,
    required this.onSettings,
    required this.onChooseFolder,
    required this.onScanDefault,
    required this.onStyleSelected,
  });

  final LibraryState library;
  final PlaybackViewState playback;
  final PlayerThemeTokens tokens;
  final VoidCallback onSettings;
  final VoidCallback onChooseFolder;
  final VoidCallback onScanDefault;
  final ValueChanged<UiStyle> onStyleSelected;

  @override
  Widget build(BuildContext context) {
    return _DesktopPanel(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: tokens.desktopControlDecoration(active: true),
                child: Icon(Icons.graphic_eq, color: tokens.ink, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '步惊云音乐',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DesktopFolderSummary(tokens: tokens, library: library),
          const SizedBox(height: 14),
          _DesktopPrimaryButton(
            tokens: tokens,
            icon: Icons.folder_open,
            label: chooseMusicFolderLabel,
            onPressed: onChooseFolder,
          ),
          const SizedBox(height: 8),
          _DesktopSecondaryButton(
            tokens: tokens,
            icon: Icons.refresh,
            label: '重新读取 ~/Music',
            onPressed: onScanDefault,
          ),
          const SizedBox(height: 22),
          Text(
            '播放外观',
            style: TextStyle(color: tokens.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _DesktopStyleSelector(
            tokens: tokens,
            playback: playback,
            onSelected: onStyleSelected,
          ),
          const Spacer(),
          _DesktopSecondaryButton(
            tokens: tokens,
            icon: Icons.tune,
            label: '设置',
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _DesktopNowPlaying extends StatelessWidget {
  const _DesktopNowPlaying({
    required this.tokens,
    required this.playback,
    required this.song,
    required this.playing,
    required this.audioHandler,
    required this.onDeleteCurrent,
    required this.onFavoriteCurrent,
    required this.onMode,
    required this.onPrevious,
    required this.onPlay,
    required this.onNext,
  });

  final PlayerThemeTokens tokens;
  final PlaybackViewState playback;
  final Song? song;
  final bool playing;
  final BujingyunAudioHandler audioHandler;
  final VoidCallback? onDeleteCurrent;
  final VoidCallback? onFavoriteCurrent;
  final VoidCallback onMode;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _DesktopPanel(
      tokens: tokens,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  playing ? '正在播放' : '已暂停',
                  style: TextStyle(color: tokens.muted, fontSize: 12),
                ),
              ),
              _DesktopIconButton(
                tokens: tokens,
                icon: Icons.delete_outline,
                iconColor: const Color(0xFFFF7A90),
                label: '删除当前音乐',
                onPressed: onDeleteCurrent,
              ),
              const SizedBox(width: 8),
              _DesktopIconButton(
                tokens: tokens,
                icon: Icons.favorite,
                iconColor: song?.favorite == true
                    ? const Color(0xFFFF5D9F)
                    : Colors.white,
                label: '收藏当前音乐',
                onPressed: onFavoriteCurrent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox.square(
                      dimension:
                          MediaQuery.sizeOf(context).height.clamp(180, 270),
                      child: ThemeVisualizer(
                        style: playback.uiStyle,
                        playing: playing,
                        tokens: tokens,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      song?.title ?? '星际漫游.mp3',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 28,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song?.meta ?? '$sampleMusicMetaPrefix / Synthwave',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.soft, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _MiniBars(playing: playing, tokens: tokens),
                  ],
                ),
              ),
            ),
          ),
          _ProgressRow(tokens: tokens, audioHandler: audioHandler),
          const SizedBox(height: 16),
          _DesktopControlStrip(
            tokens: tokens,
            mode: playback.mode,
            playing: playing,
            onMode: onMode,
            onPrevious: onPrevious,
            onPlay: onPlay,
            onNext: onNext,
          ),
        ],
      ),
    );
  }
}

class _DesktopControlStrip extends StatelessWidget {
  const _DesktopControlStrip({
    required this.tokens,
    required this.mode,
    required this.playing,
    required this.onMode,
    required this.onPrevious,
    required this.onPlay,
    required this.onNext,
  });

  final PlayerThemeTokens tokens;
  final PlaybackMode mode;
  final bool playing;
  final VoidCallback onMode;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _DesktopIconButton(
            tokens: tokens,
            icon: switch (mode) {
              PlaybackMode.shuffle => Icons.shuffle,
              PlaybackMode.repeatAll => Icons.repeat,
              PlaybackMode.repeatOne => Icons.repeat_one,
            },
            label: mode.label,
            onPressed: onMode,
            size: 42,
          ),
          const SizedBox(width: 18),
          _DesktopIconButton(
            tokens: tokens,
            icon: Icons.skip_previous,
            label: '上一首',
            onPressed: onPrevious,
            size: 44,
          ),
          const SizedBox(width: 10),
          _DesktopIconButton(
            tokens: tokens,
            icon: playing ? Icons.pause : Icons.play_arrow,
            label: playing ? '暂停' : '播放',
            onPressed: onPlay,
            size: 52,
            play: true,
          ),
          const SizedBox(width: 10),
          _DesktopIconButton(
            tokens: tokens,
            icon: Icons.skip_next,
            label: '下一首',
            onPressed: onNext,
            size: 44,
          ),
        ],
      ),
    );
  }
}

class _DesktopQueuePanel extends StatelessWidget {
  const _DesktopQueuePanel({
    required this.tokens,
    required this.library,
    required this.playback,
    required this.indices,
    required this.favoritesOnly,
    required this.onToggleFavoritesOnly,
    required this.onPlayFirst,
    required this.onSelectSong,
    required this.onFavoriteSong,
  });

  final PlayerThemeTokens tokens;
  final LibraryState library;
  final PlaybackViewState playback;
  final List<int> indices;
  final bool favoritesOnly;
  final ValueChanged<bool> onToggleFavoritesOnly;
  final VoidCallback? onPlayFirst;
  final ValueChanged<int> onSelectSong;
  final ValueChanged<int> onFavoriteSong;

  @override
  Widget build(BuildContext context) {
    return _DesktopPanel(
      tokens: tokens,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '曲库',
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${indices.length} 首',
                style: TextStyle(color: tokens.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DesktopTextChip(
                  label: '全部',
                  active: !favoritesOnly,
                  tokens: tokens,
                  onTap: () => onToggleFavoritesOnly(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DesktopTextChip(
                  label: '收藏',
                  active: favoritesOnly,
                  tokens: tokens,
                  onTap: () => onToggleFavoritesOnly(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DesktopPrimaryButton(
            tokens: tokens,
            icon: Icons.play_arrow,
            label: favoritesOnly ? '播放收藏音乐' : '播放全部音乐',
            onPressed: onPlayFirst,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: indices.isEmpty
                ? Center(
                    child: Text(
                      favoritesOnly ? '暂无收藏音乐' : library.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: tokens.muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: indices.length,
                    itemBuilder: (context, itemIndex) {
                      final songIndex = indices[itemIndex];
                      final song = library.songs[songIndex];
                      return _DesktopSongRow(
                        song: song,
                        active: playback.currentIndex == songIndex,
                        tokens: tokens,
                        onTap: () => onSelectSong(songIndex),
                        onFavorite: () => onFavoriteSong(songIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSongRow extends StatelessWidget {
  const _DesktopSongRow({
    required this.song,
    required this.active,
    required this.tokens,
    required this.onTap,
    required this.onFavorite,
  });

  final Song song;
  final bool active;
  final PlayerThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 54,
          padding: const EdgeInsets.fromLTRB(10, 7, 4, 7),
          decoration: tokens.desktopControlDecoration(active: active),
          child: Row(
            children: [
              Icon(
                active ? Icons.equalizer : Icons.music_note,
                color: active ? tokens.accent : tokens.soft,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${song.category} · ${song.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '收藏',
                onPressed: onFavorite,
                icon: Icon(
                  Icons.favorite,
                  color: song.favorite ? const Color(0xFFFF5D9F) : tokens.soft,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopFolderSummary extends StatelessWidget {
  const _DesktopFolderSummary({
    required this.tokens,
    required this.library,
  });

  final PlayerThemeTokens tokens;
  final LibraryState library;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: tokens.desktopControlDecoration(),
      child: Row(
        children: [
          Icon(Icons.folder, color: tokens.soft, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  library.folderLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  library.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopStyleSelector extends StatelessWidget {
  const _DesktopStyleSelector({
    required this.tokens,
    required this.playback,
    required this.onSelected,
  });

  final PlayerThemeTokens tokens;
  final PlaybackViewState playback;
  final ValueChanged<UiStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: UiStyle.values.map((style) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _DesktopTextChip(
              label: style.label,
              active: playback.uiStyle == style,
              tokens: tokens,
              onTap: () => onSelected(style),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _DesktopSettingStatus extends StatelessWidget {
  const _DesktopSettingStatus({
    required this.tokens,
    required this.label,
  });

  final PlayerThemeTokens tokens;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: tokens.accent, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: tokens.soft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopPrimaryButton extends StatelessWidget {
  const _DesktopPrimaryButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final PlayerThemeTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: DecoratedBox(
        decoration: tokens.playDecoration(radius: 10),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: const Color(0xFF041218), size: 17),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF041218),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopSecondaryButton extends StatelessWidget {
  const _DesktopSecondaryButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final PlayerThemeTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: tokens.panelFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: tokens.line.withAlpha(179)),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, color: tokens.soft, size: 17),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: tokens.ink, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DesktopTextChip extends StatelessWidget {
  const _DesktopTextChip({
    required this.label,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool active;
  final PlayerThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: tokens.desktopControlDecoration(active: active),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tokens.ink,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DesktopIconButton extends StatelessWidget {
  const _DesktopIconButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.size = 36,
    this.play = false,
  });

  final PlayerThemeTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double size;
  final bool play;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: play
            ? tokens.playDecoration(radius: 12)
            : tokens.desktopControlDecoration(),
        child: SizedBox(
          width: size,
          height: size,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: Icon(
              icon,
              color:
                  iconColor ?? (play ? const Color(0xFF041218) : Colors.white),
              size: size >= 50 ? 24 : 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.tokens,
    required this.onSettings,
  });

  final PlayerThemeTokens tokens;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          _IconControl(
            tokens: tokens,
            icon: Icons.settings,
            label: '设置',
            onPressed: onSettings,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '步惊云音乐',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '本地 MP3 全屏播放',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 46, height: 46),
        ],
      ),
    );
  }
}

class _TrackHeader extends StatelessWidget {
  const _TrackHeader({
    required this.song,
    required this.tokens,
    required this.onDelete,
    required this.onFavorite,
  });

  final Song? song;
  final PlayerThemeTokens tokens;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: _IconControl(
              tokens: tokens,
              icon: Icons.delete_outline,
              iconColor: const Color(0xFFFF7A90),
              label: '删除当前音乐',
              onPressed: onDelete,
              size: 42,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52),
            child: Text(
              song?.title ?? '星际漫游.mp3',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.ink,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: _IconControl(
              tokens: tokens,
              icon: Icons.favorite,
              iconColor: song?.favorite == true
                  ? const Color(0xFFFF5D9F)
                  : Colors.white,
              label: '收藏当前音乐',
              onPressed: onFavorite,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBars extends StatefulWidget {
  const _MiniBars({
    required this.playing,
    required this.tokens,
  });

  final bool playing;
  final PlayerThemeTokens tokens;

  @override
  State<_MiniBars> createState() => _MiniBarsState();
}

class _MiniBarsState extends State<_MiniBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.playing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MiniBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.playing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const heights = [18.0, 32.0, 24.0, 30.0, 20.0];
    return SizedBox(
      height: 34,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < heights.length; index += 1)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 7,
                  height: widget.playing
                      ? heights[index] *
                          (.45 + .55 * _wave(_controller.value, index))
                      : heights[index],
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.tokens.accent, widget.tokens.accentAlt],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _wave(double value, int index) {
    return (math.sin(value * math.pi * 2 + index * .9) + 1) / 2;
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.tokens,
    required this.audioHandler,
  });

  final PlayerThemeTokens tokens;
  final BujingyunAudioHandler audioHandler;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audioHandler.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = audioHandler.duration ?? Duration.zero;
        final max = duration.inMilliseconds <= 0
            ? 1.0
            : duration.inMilliseconds.toDouble();
        final value = position.inMilliseconds.clamp(0, max.toInt()).toDouble();

        return Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                formatDurationMs(position.inMilliseconds),
                style: TextStyle(color: tokens.muted, fontSize: 12),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: tokens.accent,
                  inactiveTrackColor: Colors.black.withAlpha(95),
                ),
                child: Slider(
                  value: value,
                  max: max,
                  onChanged: duration.inMilliseconds <= 0
                      ? null
                      : (next) => audioHandler.seek(
                            Duration(milliseconds: next.round()),
                          ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                duration.inMilliseconds <= 0
                    ? '00:00'
                    : formatDurationMs(duration.inMilliseconds),
                textAlign: TextAlign.end,
                style: TextStyle(color: tokens.muted, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.tokens,
    required this.mode,
    required this.playing,
    required this.onMode,
    required this.onPrevious,
    required this.onPlay,
    required this.onNext,
    required this.onPlaylist,
  });

  final PlayerThemeTokens tokens;
  final PlaybackMode mode;
  final bool playing;
  final VoidCallback onMode;
  final VoidCallback onPrevious;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onPlaylist;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Row(
        children: [
          _IconControl(
            tokens: tokens,
            icon: switch (mode) {
              PlaybackMode.shuffle => Icons.shuffle,
              PlaybackMode.repeatAll => Icons.repeat,
              PlaybackMode.repeatOne => Icons.repeat_one,
            },
            label: mode.label,
            onPressed: onMode,
            size: 58,
          ),
          const Spacer(),
          _IconControl(
            tokens: tokens,
            icon: Icons.skip_previous,
            label: '上一首',
            onPressed: onPrevious,
            size: 58,
          ),
          const SizedBox(width: 14),
          _IconControl(
            tokens: tokens,
            icon: playing ? Icons.pause : Icons.play_arrow,
            label: playing ? '暂停' : '播放',
            onPressed: onPlay,
            size: 72,
            play: true,
          ),
          const SizedBox(width: 14),
          _IconControl(
            tokens: tokens,
            icon: Icons.skip_next,
            label: '下一首',
            onPressed: onNext,
            size: 58,
          ),
          const Spacer(),
          _IconControl(
            tokens: tokens,
            icon: Icons.queue_music,
            label: '歌单',
            onPressed: onPlaylist,
            size: 58,
          ),
        ],
      ),
    );
  }
}

class _PlaylistPanel extends ConsumerStatefulWidget {
  const _PlaylistPanel({
    required this.tokens,
    required this.initialFavorites,
  });

  final PlayerThemeTokens tokens;
  final bool initialFavorites;

  @override
  ConsumerState<_PlaylistPanel> createState() => _PlaylistPanelState();
}

class _PlaylistPanelState extends ConsumerState<_PlaylistPanel> {
  late bool favoritesOnly = widget.initialFavorites;

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryControllerProvider);
    final playback = ref.watch(playbackControllerProvider);
    final controller = ref.read(playbackControllerProvider.notifier);
    final indices = ref
        .read(libraryControllerProvider.notifier)
        .sortedSongIndices(favoritesOnly: favoritesOnly);

    return _PanelShell(
      tokens: widget.tokens,
      title: '歌单',
      subtitle: '全部音乐 / 收藏音乐',
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .68,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TextChipButton(
                    label: '全部音乐',
                    active: !favoritesOnly,
                    tokens: widget.tokens,
                    onTap: () => setState(() => favoritesOnly = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TextChipButton(
                    label: '收藏音乐',
                    active: favoritesOnly,
                    tokens: widget.tokens,
                    onTap: () => setState(() => favoritesOnly = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: DecoratedBox(
                decoration: widget.tokens.playDecoration(),
                child: TextButton(
                  onPressed: indices.isEmpty
                      ? null
                      : () async {
                          final selected = indices.first;
                          if (favoritesOnly) {
                            controller.activateFavoriteQueue(
                              selected,
                              library.songs,
                            );
                            await controller.selectSong(
                              ref.read(playbackControllerProvider).currentIndex,
                              songs: library.songs,
                              start: true,
                              keepQueue: true,
                            );
                          } else {
                            await controller.selectSong(
                              selected,
                              songs: library.songs,
                              start: true,
                            );
                          }
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                  child: Text(
                    favoritesOnly ? '播放收藏音乐' : '播放全部音乐',
                    style: const TextStyle(
                      color: Color(0xFF041218),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: indices.isEmpty
                  ? Center(
                      child: Text(
                        favoritesOnly ? '暂无收藏音乐' : '暂无本地音乐',
                        style: TextStyle(color: widget.tokens.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: indices.length,
                      itemBuilder: (context, itemIndex) {
                        final songIndex = indices[itemIndex];
                        final song = library.songs[songIndex];
                        return _SongTile(
                          song: song,
                          active: playback.currentIndex == songIndex,
                          tokens: widget.tokens,
                          onTap: () async {
                            if (favoritesOnly) {
                              controller.activateFavoriteQueue(
                                songIndex,
                                library.songs,
                              );
                              await controller.selectSong(
                                songIndex,
                                songs: library.songs,
                                start: true,
                                keepQueue: true,
                              );
                            } else {
                              await controller.selectSong(
                                songIndex,
                                songs: library.songs,
                                start: true,
                              );
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          onFavorite: () => ref
                              .read(libraryControllerProvider.notifier)
                              .toggleFavorite(songIndex),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({
    required this.song,
    required this.active,
    required this.tokens,
    required this.onTap,
    required this.onFavorite,
  });

  final Song song;
  final bool active;
  final PlayerThemeTokens tokens;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(10),
          decoration: tokens.controlDecoration(active: active),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tokens.activeFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.music_note, color: tokens.ink, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${song.category} · ${song.size}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tokens.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  song.duration,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: tokens.soft, fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: '收藏',
                onPressed: onFavorite,
                icon: Icon(
                  Icons.favorite,
                  color: song.favorite ? const Color(0xFFFF5D9F) : Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderSummary extends StatelessWidget {
  const _FolderSummary({
    required this.tokens,
    required this.library,
  });

  final PlayerThemeTokens tokens;
  final LibraryState library;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: tokens.controlDecoration(),
          child: Icon(Icons.folder, color: tokens.ink),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                library.folderLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                library.message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PanelShell extends StatelessWidget {
  const _PanelShell({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final PlayerThemeTokens tokens;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: tokens.panelDecoration(strong: true),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .82,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: tokens.ink,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: tokens.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _IconControl(
                        tokens: tokens,
                        icon: Icons.close,
                        label: '关闭菜单',
                        onPressed: () => Navigator.pop(context),
                        size: 40,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(child: child),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TextChipButton extends StatelessWidget {
  const _TextChipButton({
    required this.label,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  final String label;
  final bool active;
  final PlayerThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: tokens.controlDecoration(active: active),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tokens.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _IconControl extends StatelessWidget {
  const _IconControl({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
    this.size = 46,
    this.play = false,
  });

  final PlayerThemeTokens tokens;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final double size;
  final bool play;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: DecoratedBox(
        decoration: play ? tokens.playDecoration() : tokens.controlDecoration(),
        child: SizedBox(
          width: size,
          height: size,
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color:
                  iconColor ?? (play ? const Color(0xFF041218) : Colors.white),
              size: size >= 70 ? 30 : 22,
            ),
          ),
        ),
      ),
    );
  }
}
