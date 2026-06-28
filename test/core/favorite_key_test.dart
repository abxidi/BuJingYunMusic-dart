import 'package:flutter_test/flutter_test.dart';
import 'package:bujingyun_music/core/models/song.dart';
import 'package:bujingyun_music/features/preferences/data/favorite_keys.dart';

void main() {
  test('favorite key matches the Android v2 title duration size format', () {
    const song = Song(
      title: ' 星际漫游.MP3 ',
      meta: '手机存储 / Music / Synthwave',
      duration: '03:48',
      size: '8.6 MB',
      uri: 'content://media/external/audio/media/1',
    );

    expect(favoriteKey(song), 'v2|星际漫游.mp3|03:48|8.6 mb');
  });

  test('legacy favorite key uses uri when present and title meta otherwise',
      () {
    const withUri = Song(
      title: '星际漫游.mp3',
      meta: '手机存储 / Music / Synthwave',
      duration: '03:48',
      size: '8.6 MB',
      uri: 'content://media/external/audio/media/1',
    );
    const sample = Song(
      title: '星际漫游.mp3',
      meta: '手机存储 / Music / Synthwave',
      duration: '03:48',
      size: '8.6 MB',
    );

    expect(legacyFavoriteKey(withUri), withUri.uri);
    expect(legacyFavoriteKey(sample), '星际漫游.mp3|手机存储 / Music / Synthwave');
  });
}
