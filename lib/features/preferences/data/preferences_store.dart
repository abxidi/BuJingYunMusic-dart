import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/ui_style.dart';

class PreferencesStore {
  PreferencesStore(this._preferences);

  static const favoriteKeysKey = 'favorite_song_keys';
  static const uiStyleKey = 'ui_style';

  final SharedPreferences _preferences;

  Set<String> loadFavoriteKeys() {
    return _preferences.getStringList(favoriteKeysKey)?.toSet() ?? <String>{};
  }

  Future<void> saveFavoriteKeys(Set<String> keys) {
    return _preferences.setStringList(favoriteKeysKey, keys.toList()..sort());
  }

  UiStyle loadUiStyle() {
    return UiStyle.fromStoredValue(_preferences.getInt(uiStyleKey) ?? 0);
  }

  Future<void> saveUiStyle(UiStyle style) {
    return _preferences.setInt(uiStyleKey, style.androidValue);
  }
}
