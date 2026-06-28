import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:bujingyun_music/core/models/playback_mode.dart';
import 'package:bujingyun_music/core/models/song.dart';
import 'package:bujingyun_music/features/player/application/playback_queue_controller.dart';

void main() {
  const songs = [
    Song(title: 'A.mp3', meta: 'Music / A', duration: '01:00', size: '1.0 MB'),
    Song(title: 'B.mp3', meta: 'Music / B', duration: '02:00', size: '2.0 MB'),
    Song(title: 'C.mp3', meta: 'Music / C', duration: '03:00', size: '3.0 MB'),
  ];

  test('repeat all next and previous wrap around all songs', () {
    final queue = PlaybackQueueController(songCount: songs.length);
    queue.setMode(PlaybackMode.repeatAll);
    queue.selectSong(2);

    expect(queue.playNext(manual: true, songs: songs), 0);
    expect(queue.playPrevious(songs: songs), 2);
  });

  test('repeat one repeats current song only on automatic completion', () {
    final queue = PlaybackQueueController(songCount: songs.length);
    queue.setMode(PlaybackMode.repeatOne);
    queue.selectSong(1);

    expect(queue.playNext(manual: false, songs: songs), 1);
    expect(queue.playNext(manual: true, songs: songs), 2);
  });

  test('favorite queue restricts previous and next to favorite songs', () {
    final favoriteSongs = [
      songs[0].copyWith(favorite: true),
      songs[1],
      songs[2].copyWith(favorite: true),
    ];
    final queue = PlaybackQueueController(songCount: favoriteSongs.length);
    queue.activateFavoriteQueue(2, favoriteSongs);

    expect(queue.playNext(manual: true, songs: favoriteSongs), 0);
    expect(queue.playPrevious(songs: favoriteSongs), 2);
  });

  test('shuffle avoids returning the current song when alternatives exist', () {
    final queue = PlaybackQueueController(
      songCount: songs.length,
      random: Random(0),
    );
    queue.setMode(PlaybackMode.shuffle);
    queue.selectSong(0);

    final next = queue.playNext(manual: true, songs: songs);

    expect(next, isNot(0));
    expect(next, inInclusiveRange(0, songs.length - 1));
  });
}
