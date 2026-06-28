import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_labels.dart';
import '../../preferences/application/favorites_controller.dart';
import '../data/music_library_repository.dart';
import '../data/sample_songs.dart';
import 'library_state.dart';

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController({
    required MusicLibraryRepository repository,
    required FavoritesController favorites,
  })  : _repository = repository,
        _favorites = favorites,
        super(
          LibraryState(
            songs: favorites.applyPersistedFavorites(sampleSongs),
            folderLabel: defaultMusicFolderLabel,
            message: '等待授权后读取本机音频',
            loading: false,
          ),
        );

  final MusicLibraryRepository _repository;
  final FavoritesController _favorites;

  Future<void> scanAudioStore() async {
    state = state.copyWith(loading: true, message: '读取中');
    try {
      final scanned = _favorites.applyPersistedFavorites(
        await _repository.scanAudioStore(),
      );
      if (scanned.isEmpty) {
        state = state.copyWith(
          loading: false,
          message: '暂无本地音乐',
        );
        return;
      }
      state = state.copyWith(
        songs: scanned,
        loading: false,
        message: '已读取 ${scanned.length} 首音频',
        folderLabel: platformMusicFolderLabel,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        message: '需要音频读取权限',
      );
    }
  }

  Future<void> pickAndScanFolder() async {
    state = state.copyWith(loading: true, message: '读取中');
    try {
      final scanned = _favorites.applyPersistedFavorites(
        await _repository.pickAndScanFolder(),
      );
      if (scanned.isEmpty) {
        state = state.copyWith(
          loading: false,
          message: '当前目录及子目录未找到音频',
        );
        return;
      }
      state = state.copyWith(
        songs: scanned,
        loading: false,
        message: '已读取 ${scanned.length} 首音频',
        folderLabel: '所选目录 / 子目录',
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        message: '无法读取所选目录',
      );
    }
  }

  Future<void> toggleFavorite(int index) async {
    if (index < 0 || index >= state.songs.length) {
      return;
    }
    final updated = [...state.songs];
    updated[index] = await _favorites.toggleFavorite(updated[index]);
    state = state.copyWith(songs: updated);
  }

  Future<bool> deleteSong(int index) async {
    if (index < 0 || index >= state.songs.length) {
      return false;
    }
    final song = state.songs[index];
    state = state.copyWith(loading: true, message: '正在删除 ${song.title}');
    try {
      final deleted = await _repository.deleteSong(song);
      if (!deleted) {
        state = state.copyWith(
          loading: false,
          message: '无法删除当前歌曲',
        );
        return false;
      }

      await _favorites.removeFavorite(song);
      final updated = [...state.songs]..removeAt(index);
      state = state.copyWith(
        songs: updated,
        loading: false,
        message: updated.isEmpty ? '当前曲库为空' : '已删除 ${song.title}',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        loading: false,
        message: '删除失败，需要文件写入权限',
      );
      return false;
    }
  }

  List<int> sortedSongIndices({required bool favoritesOnly}) {
    final indices = <int>[];
    for (var index = 0; index < state.songs.length; index += 1) {
      if (!favoritesOnly || state.songs[index].favorite) {
        indices.add(index);
      }
    }
    indices.sort((left, right) {
      final result =
          state.songs[left].title.compareTo(state.songs[right].title);
      return result != 0 ? result : left - right;
    });
    return indices;
  }
}
