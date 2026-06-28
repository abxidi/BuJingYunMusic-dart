import '../../../core/models/song.dart';
import '../data/favorite_keys.dart';
import '../data/preferences_store.dart';

class FavoritesController {
  FavoritesController(this._store);

  final PreferencesStore _store;

  List<Song> applyPersistedFavorites(List<Song> songs) {
    final keys = _store.loadFavoriteKeys();
    var migrated = false;
    final updated = <Song>[];

    for (final song in songs) {
      final stableKey = favoriteKey(song);
      if (keys.contains(stableKey)) {
        updated.add(song.copyWith(favorite: true));
        continue;
      }

      final legacyKey = legacyFavoriteKey(song);
      final isFavorite = keys.contains(legacyKey);
      if (isFavorite && keys.add(stableKey)) {
        migrated = true;
      }
      updated.add(song.copyWith(favorite: isFavorite));
    }

    if (migrated) {
      _store.saveFavoriteKeys(keys);
    }
    return updated;
  }

  Future<Song> toggleFavorite(Song song) async {
    final keys = _store.loadFavoriteKeys();
    final stableKey = favoriteKey(song);
    final legacyKey = legacyFavoriteKey(song);
    final updated = song.copyWith(favorite: !song.favorite);

    if (updated.favorite) {
      keys
        ..add(stableKey)
        ..add(legacyKey);
    } else {
      keys
        ..remove(stableKey)
        ..remove(legacyKey);
    }

    await _store.saveFavoriteKeys(keys);
    return updated;
  }

  Future<void> removeFavorite(Song song) async {
    final keys = _store.loadFavoriteKeys()
      ..remove(favoriteKey(song))
      ..remove(legacyFavoriteKey(song));
    await _store.saveFavoriteKeys(keys);
  }
}
