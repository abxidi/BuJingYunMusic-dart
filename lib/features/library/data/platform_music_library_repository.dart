import 'package:flutter/services.dart';

import '../../../core/models/song.dart';
import 'music_library_repository.dart';

class PlatformMusicLibraryRepository implements MusicLibraryRepository {
  PlatformMusicLibraryRepository({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('com.novapulse.mp3/music_library');

  final MethodChannel _channel;

  @override
  Future<List<Song>> scanAudioStore() async {
    final result = await _channel.invokeListMethod<Object?>('scanAudioStore');
    return _songsFromPlatform(result);
  }

  @override
  Future<List<Song>> pickAndScanFolder() async {
    final result = await _channel.invokeListMethod<Object?>('pickAndScanFolder');
    return _songsFromPlatform(result);
  }

  List<Song> _songsFromPlatform(List<Object?>? result) {
    if (result == null) {
      return const <Song>[];
    }
    return result
        .whereType<Map<Object?, Object?>>()
        .map(Song.fromMap)
        .where((song) => song.duration != '--:--' || song.uri != null)
        .toList(growable: false);
  }
}
