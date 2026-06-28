import '../../../core/models/song.dart';

abstract class MusicLibraryRepository {
  Future<List<Song>> scanAudioStore();

  Future<List<Song>> pickAndScanFolder();

  Future<bool> deleteSong(Song song);
}
