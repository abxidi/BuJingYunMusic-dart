import '../../../core/models/playback_mode.dart';
import '../../../core/models/ui_style.dart';

class PlaybackViewState {
  const PlaybackViewState({
    required this.currentIndex,
    required this.mode,
    required this.uiStyle,
    required this.favoriteQueueActive,
    this.lastMessage,
  });

  final int currentIndex;
  final PlaybackMode mode;
  final UiStyle uiStyle;
  final bool favoriteQueueActive;
  final String? lastMessage;

  PlaybackViewState copyWith({
    int? currentIndex,
    PlaybackMode? mode,
    UiStyle? uiStyle,
    bool? favoriteQueueActive,
    String? lastMessage,
  }) {
    return PlaybackViewState(
      currentIndex: currentIndex ?? this.currentIndex,
      mode: mode ?? this.mode,
      uiStyle: uiStyle ?? this.uiStyle,
      favoriteQueueActive: favoriteQueueActive ?? this.favoriteQueueActive,
      lastMessage: lastMessage,
    );
  }
}
