import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/song.dart';
import '../../../core/models/ui_style.dart';
import '../../../core/platform/platform_labels.dart';
import '../../preferences/data/favorite_keys.dart';
import '../../preferences/data/preferences_store.dart';
import 'bujingyun_audio_handler.dart';
import 'playback_queue_controller.dart';
import 'playback_view_state.dart';

class PlaybackController extends StateNotifier<PlaybackViewState> {
  PlaybackController({
    required BujingyunAudioHandler audioHandler,
    required PreferencesStore preferencesStore,
  })  : _audioHandler = audioHandler,
        _preferencesStore = preferencesStore,
        _queue = PlaybackQueueController(songCount: 0),
        super(
          PlaybackViewState(
            currentIndex: 0,
            mode: preferencesStore.loadPlaybackMode(),
            uiStyle: preferencesStore.loadUiStyle(),
            favoriteQueueActive: false,
          ),
        ) {
    _queue.setMode(state.mode);
    _completionSub = _audioHandler.customEvent.listen((event) {
      if (event == 'completed') {
        unawaited(playNext(manual: false, songs: _lastSongs));
      }
    });
  }

  final BujingyunAudioHandler _audioHandler;
  final PreferencesStore _preferencesStore;
  final PlaybackQueueController _queue;
  late final StreamSubscription<Object?> _completionSub;
  List<Song> _lastSongs = const <Song>[];

  Future<void> selectSong(
    int index, {
    required List<Song> songs,
    bool start = false,
    bool keepQueue = false,
  }) async {
    _lastSongs = songs;
    _queue.updateSongCount(songs.length);
    _queue.selectSong(index, keepQueue: keepQueue);
    await _persistCurrentSong(songs);
    state = state.copyWith(
      currentIndex: _queue.currentIndex,
      favoriteQueueActive: _queue.favoriteQueueActive,
    );
    if (start) {
      await playCurrent(songs);
    } else {
      await _audioHandler.stop();
    }
  }

  Future<void> playCurrent(List<Song> songs) async {
    if (songs.isEmpty || state.currentIndex >= songs.length) {
      return;
    }
    _lastSongs = songs;
    await _persistCurrentSong(songs);
    final song = songs[state.currentIndex];
    final started = await _audioHandler.playSong(song);
    if (!started) {
      state = state.copyWith(lastMessage: playbackUnavailableMessage);
    }
  }

  Future<void> togglePlay(List<Song> songs, PlaybackState playbackState) async {
    if (playbackState.playing) {
      await _audioHandler.pause();
      return;
    }
    if (playbackState.processingState == AudioProcessingState.ready) {
      await _audioHandler.play();
      return;
    }
    await playCurrent(songs);
  }

  Future<void> playPrevious({required List<Song> songs}) async {
    _lastSongs = songs;
    final index = _queue.playPrevious(songs: songs);
    state = state.copyWith(
      currentIndex: index,
      favoriteQueueActive: _queue.favoriteQueueActive,
    );
    await _persistCurrentSong(songs);
    await playCurrent(songs);
  }

  Future<void> playNext({
    required bool manual,
    required List<Song> songs,
  }) async {
    _lastSongs = songs;
    final index = _queue.playNext(manual: manual, songs: songs);
    state = state.copyWith(
      currentIndex: index,
      favoriteQueueActive: _queue.favoriteQueueActive,
    );
    await _persistCurrentSong(songs);
    await playCurrent(songs);
  }

  void activateFavoriteQueue(int selectedIndex, List<Song> songs) {
    _lastSongs = songs;
    _queue.updateSongCount(songs.length);
    _queue.activateFavoriteQueue(selectedIndex, songs);
    unawaited(_persistCurrentSong(songs));
    state = state.copyWith(
      currentIndex: _queue.currentIndex,
      favoriteQueueActive: _queue.favoriteQueueActive,
    );
  }

  void refreshFavoriteQueue(List<Song> songs) {
    _lastSongs = songs;
    _queue.updateSongCount(songs.length);
    _queue.refreshFavoriteQueue(songs);
    unawaited(_persistCurrentSong(songs));
    state = state.copyWith(
      currentIndex: _queue.currentIndex,
      favoriteQueueActive: _queue.favoriteQueueActive,
    );
  }

  Future<void> switchMode() async {
    final mode = _queue.switchMode();
    await _preferencesStore.savePlaybackMode(mode);
    state = state.copyWith(mode: mode);
  }

  Future<void> restoreSelection(List<Song> songs) async {
    _lastSongs = songs;
    _queue.updateSongCount(songs.length);
    if (songs.isEmpty) {
      await _audioHandler.stop();
      await _preferencesStore.clearCurrentSongKey();
      state = state.copyWith(currentIndex: 0, favoriteQueueActive: false);
      return;
    }

    final storedKey = _preferencesStore.loadCurrentSongKey();
    final restoredIndex = storedKey == null
        ? -1
        : songs.indexWhere((song) => favoriteKey(song) == storedKey);
    _queue.selectSong(restoredIndex >= 0 ? restoredIndex : 0);
    await _persistCurrentSong(songs);
    state = state.copyWith(
      currentIndex: _queue.currentIndex,
      favoriteQueueActive: _queue.favoriteQueueActive,
    );
  }

  Future<void> removeSongAt({
    required int deletedIndex,
    required List<Song> songs,
    required bool wasPlaying,
  }) async {
    _lastSongs = songs;
    _queue.updateSongCount(songs.length);
    if (songs.isEmpty) {
      await _audioHandler.stop();
      await _preferencesStore.clearCurrentSongKey();
      state = state.copyWith(currentIndex: 0, favoriteQueueActive: false);
      return;
    }

    final nextIndex = deletedIndex.clamp(0, songs.length - 1).toInt();
    _queue.selectSong(nextIndex);
    await _persistCurrentSong(songs);
    state = state.copyWith(
      currentIndex: _queue.currentIndex,
      favoriteQueueActive: _queue.favoriteQueueActive,
    );
    if (wasPlaying) {
      await playCurrent(songs);
    } else {
      await _audioHandler.stop();
    }
  }

  Future<void> setUiStyle(UiStyle style) async {
    await _preferencesStore.saveUiStyle(style);
    state = state.copyWith(uiStyle: style);
  }

  Future<void> _persistCurrentSong(List<Song> songs) async {
    if (songs.isEmpty || _queue.currentIndex >= songs.length) {
      await _preferencesStore.clearCurrentSongKey();
      return;
    }
    await _preferencesStore
        .saveCurrentSongKey(favoriteKey(songs[_queue.currentIndex]));
  }

  @override
  void dispose() {
    _completionSub.cancel();
    super.dispose();
  }
}
