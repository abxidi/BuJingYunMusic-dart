import '../../../core/models/song.dart';

String favoriteKey(Song song) {
  return 'v2|'
      '${_normalizeFavoritePart(song.title)}|'
      '${_normalizeFavoritePart(song.duration)}|'
      '${_normalizeFavoritePart(song.size)}';
}

String legacyFavoriteKey(Song song) {
  if (song.uri != null && song.uri!.trim().isNotEmpty) {
    return song.uri!;
  }
  return '${song.title}|${song.meta}';
}

String _normalizeFavoritePart(String value) {
  return value.trim().toLowerCase();
}
