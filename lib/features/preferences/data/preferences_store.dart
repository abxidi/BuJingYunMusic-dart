import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/playback_mode.dart';
import '../../../core/models/ui_style.dart';

class PreferencesStore {
  PreferencesStore(this._preferences);

  static const favoriteKeysKey = 'favorite_song_keys';
  static const uiStyleKey = 'ui_style';
  static const playbackModeKey = 'playback_mode';
  static const currentSongKey = 'current_song_key';

  final SharedPreferences _preferences;

  Set<String> loadFavoriteKeys() {
    return _preferences.getStringList(favoriteKeysKey)?.toSet() ?? <String>{};
  }

  Future<void> saveFavoriteKeys(Set<String> keys) {
    return _preferences.setStringList(favoriteKeysKey, keys.toList()..sort());
  }

  PlaybackMode loadPlaybackMode() {
    final index =
        _preferences.getInt(playbackModeKey) ?? PlaybackMode.shuffle.index;
    if (index < 0 || index >= PlaybackMode.values.length) {
      return PlaybackMode.shuffle;
    }
    return PlaybackMode.values[index];
  }

  Future<void> savePlaybackMode(PlaybackMode mode) {
    return _preferences.setInt(playbackModeKey, mode.index);
  }

  String? loadCurrentSongKey() {
    final value = _preferences.getString(currentSongKey);
    return value == null || value.trim().isEmpty ? null : value;
  }

  Future<void> saveCurrentSongKey(String key) {
    return _preferences.setString(currentSongKey, key);
  }

  Future<void> clearCurrentSongKey() {
    return _preferences.remove(currentSongKey);
  }

  UiStyle loadUiStyle() {
    return UiStyle.fromStoredValue(_preferences.getInt(uiStyleKey) ?? 0);
  }

  Future<void> saveUiStyle(UiStyle style) {
    return _preferences.setInt(uiStyleKey, style.androidValue);
  }
}
