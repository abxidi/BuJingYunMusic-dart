import '../../../core/models/song.dart';

class LibraryState {
  const LibraryState({
    required this.songs,
    required this.folderLabel,
    required this.message,
    required this.loading,
  });

  final List<Song> songs;
  final String folderLabel;
  final String message;
  final bool loading;

  LibraryState copyWith({
    List<Song>? songs,
    String? folderLabel,
    String? message,
    bool? loading,
  }) {
    return LibraryState(
      songs: songs ?? this.songs,
      folderLabel: folderLabel ?? this.folderLabel,
      message: message ?? this.message,
      loading: loading ?? this.loading,
    );
  }
}
