import 'package:bujingyun_music/core/models/playback_mode.dart';
import 'package:bujingyun_music/core/models/ui_style.dart';
import 'package:bujingyun_music/features/preferences/data/preferences_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('playback mode falls back to shuffle when stored value is invalid',
      () async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.playbackModeKey: 99,
    });
    final store = PreferencesStore(await SharedPreferences.getInstance());

    expect(store.loadPlaybackMode(), PlaybackMode.shuffle);

    await store.savePlaybackMode(PlaybackMode.repeatOne);
    expect(store.loadPlaybackMode(), PlaybackMode.repeatOne);
  });

  test('current song key can be saved, loaded, and cleared', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PreferencesStore(await SharedPreferences.getInstance());

    expect(store.loadCurrentSongKey(), isNull);

    await store.saveCurrentSongKey('v2|song|03:00|3.0 mb');
    expect(store.loadCurrentSongKey(), 'v2|song|03:00|3.0 mb');

    await store.clearCurrentSongKey();
    expect(store.loadCurrentSongKey(), isNull);
  });

  test('legacy liquid style still falls back to classic', () async {
    SharedPreferences.setMockInitialValues({
      PreferencesStore.uiStyleKey: 1,
    });
    final store = PreferencesStore(await SharedPreferences.getInstance());

    expect(store.loadUiStyle(), UiStyle.classic);
  });
}
