import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../core/models/playback_mode.dart';
import '../../../core/models/song.dart';
import '../../../core/models/ui_style.dart';
import '../../../core/platform/platform_labels.dart';
import '../../../core/utils/formatters.dart';
import '../../visualizer/presentation/visualizer_widgets.dart';
import '../application/bujingyun_audio_handler.dart';
import '../../library/application/library_state.dart';
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

    return StreamBuilder<PlaybackState>(
      stream: audioHandler.playbackState,
      builder: (context, snapshot) {
        final playbackState = snapshot.data ?? PlaybackState();
        final playing = playbackState.playing;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: tokens.rootDecoration(),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
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
                              onSettings: () =>
                                  _showSettings(context, ref, tokens),
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
                              onPrevious: () =>
                                  playbackController.playPrevious(songs: songs),
                              onPlay: () => playbackController.togglePlay(
                                songs,
                                playbackState,
                              ),
                              onNext: () => playbackController.playNext(
                                manual: true,
                                songs: songs,
                              ),
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
    required this.onFavorite,
  });

  final Song? song;
  final PlayerThemeTokens tokens;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
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
