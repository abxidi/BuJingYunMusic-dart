import 'dart:math';

import '../../../core/models/playback_mode.dart';
import '../../../core/models/song.dart';

class PlaybackQueueController {
  PlaybackQueueController({
    required int songCount,
    Random? random,
  })  : _songCount = songCount,
        _random = random ?? Random();

  final Random _random;
  int _songCount;
  int currentIndex = 0;
  int activeQueuePosition = -1;
  bool favoriteQueueActive = false;
  PlaybackMode mode = PlaybackMode.shuffle;
  final List<int> activeQueue = <int>[];

  void updateSongCount(int songCount) {
    _songCount = songCount;
    if (_songCount == 0) {
      currentIndex = 0;
      activeQueuePosition = -1;
      activeQueue.clear();
      favoriteQueueActive = false;
      return;
    }
    if (currentIndex >= _songCount) {
      currentIndex = _songCount - 1;
    }
  }

  void setMode(PlaybackMode nextMode) {
    mode = nextMode;
  }

  PlaybackMode switchMode() {
    mode = mode.next;
    return mode;
  }

  void selectSong(int index, {bool keepQueue = false}) {
    if (index < 0 || index >= _songCount) {
      return;
    }
    if (!keepQueue) {
      activeQueue.clear();
      activeQueuePosition = -1;
      favoriteQueueActive = false;
    }
    currentIndex = index;
  }

  void activateFavoriteQueue(int selectedIndex, List<Song> songs) {
    favoriteQueueActive = true;
    activeQueue
      ..clear()
      ..addAll(_favoriteIndices(songs));
    activeQueuePosition = activeQueue.indexOf(selectedIndex);
    if (activeQueuePosition < 0 && activeQueue.isNotEmpty) {
      activeQueuePosition = 0;
    }
    if (activeQueue.isNotEmpty) {
      currentIndex = activeQueue[activeQueuePosition];
    }
  }

  void refreshFavoriteQueue(List<Song> songs) {
    if (!favoriteQueueActive) {
      return;
    }
    activeQueue
      ..clear()
      ..addAll(_favoriteIndices(songs));
    activeQueuePosition = activeQueue.indexOf(currentIndex);
    if (activeQueuePosition < 0 && activeQueue.isNotEmpty) {
      activeQueuePosition = 0;
      currentIndex = activeQueue[activeQueuePosition];
    }
  }

  int playPrevious({required List<Song> songs}) {
    updateSongCount(songs.length);
    if (_songCount == 0) {
      return currentIndex;
    }

    if (favoriteQueueActive) {
      refreshFavoriteQueue(songs);
      if (activeQueue.isEmpty) {
        return currentIndex;
      }
      activeQueuePosition = activeQueuePosition <= 0
          ? activeQueue.length - 1
          : activeQueuePosition - 1;
      currentIndex = activeQueue[activeQueuePosition];
      return currentIndex;
    }

    currentIndex = currentIndex - 1;
    if (currentIndex < 0) {
      currentIndex = _songCount - 1;
    }
    return currentIndex;
  }

  int playNext({
    required bool manual,
    required List<Song> songs,
  }) {
    updateSongCount(songs.length);
    if (_songCount == 0) {
      return currentIndex;
    }

    if (favoriteQueueActive) {
      refreshFavoriteQueue(songs);
      if (activeQueue.isEmpty) {
        return currentIndex;
      }
      if (!manual && mode == PlaybackMode.repeatOne) {
        currentIndex = activeQueue[activeQueuePosition];
        return currentIndex;
      }
      if (mode == PlaybackMode.shuffle && activeQueue.length > 1) {
        var nextQueuePosition = _random.nextInt(activeQueue.length);
        if (nextQueuePosition == activeQueuePosition) {
          nextQueuePosition = (nextQueuePosition + 1) % activeQueue.length;
        }
        activeQueuePosition = nextQueuePosition;
      } else {
        activeQueuePosition = (activeQueuePosition + 1) % activeQueue.length;
      }
      currentIndex = activeQueue[activeQueuePosition];
      return currentIndex;
    }

    if (!manual && mode == PlaybackMode.repeatOne) {
      return currentIndex;
    }
    if (mode == PlaybackMode.shuffle && _songCount > 1) {
      var next = _random.nextInt(_songCount);
      if (next == currentIndex) {
        next = (next + 1) % _songCount;
      }
      currentIndex = next;
      return currentIndex;
    }
    currentIndex = (currentIndex + 1) % _songCount;
    return currentIndex;
  }

  List<int> _favoriteIndices(List<Song> songs) {
    final indices = <int>[];
    for (var index = 0; index < songs.length; index += 1) {
      if (songs[index].favorite) {
        indices.add(index);
      }
    }
    indices.sort((left, right) {
      final titleCompare = songs[left].title.compareTo(songs[right].title);
      return titleCompare != 0 ? titleCompare : left - right;
    });
    return indices;
  }
}
