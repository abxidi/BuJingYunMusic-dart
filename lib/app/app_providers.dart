import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/library/application/library_controller.dart';
import '../features/library/application/library_state.dart';
import '../features/library/data/music_library_repository.dart';
import '../features/library/data/platform_music_library_repository.dart';
import '../features/player/application/bujingyun_audio_handler.dart';
import '../features/player/application/playback_controller.dart';
import '../features/player/application/playback_view_state.dart';
import '../features/preferences/application/favorites_controller.dart';
import '../features/preferences/data/preferences_store.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be provided at startup.');
});

final audioHandlerProvider = Provider<BujingyunAudioHandler>((ref) {
  throw UnimplementedError('AudioHandler must be provided at startup.');
});

final preferencesStoreProvider = Provider<PreferencesStore>((ref) {
  return PreferencesStore(ref.watch(sharedPreferencesProvider));
});

final favoritesControllerProvider = Provider<FavoritesController>((ref) {
  return FavoritesController(ref.watch(preferencesStoreProvider));
});

final musicLibraryRepositoryProvider = Provider<MusicLibraryRepository>((ref) {
  return PlatformMusicLibraryRepository();
});

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  return LibraryController(
    repository: ref.watch(musicLibraryRepositoryProvider),
    favorites: ref.watch(favoritesControllerProvider),
  )..scanAudioStore();
});

final playbackControllerProvider =
    StateNotifierProvider<PlaybackController, PlaybackViewState>((ref) {
  return PlaybackController(
    audioHandler: ref.watch(audioHandlerProvider),
    preferencesStore: ref.watch(preferencesStoreProvider),
  );
});

Future<BujingyunAudioHandler> initAudioHandler() {
  return AudioService.init(
    builder: BujingyunAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.novapulse.mp3.playback',
      androidNotificationChannelName: '音乐播放',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
}
