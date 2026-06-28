import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/models/song.dart';

class BujingyunAudioHandler extends BaseAudioHandler with SeekHandler {
  BujingyunAudioHandler() {
    _init();
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playbackEventStream.listen(_broadcastState);
    _player.processingStateStream.listen((processingState) {
      if (processingState == ProcessingState.completed) {
        customEvent.add('completed');
      }
    });
  }

  Future<bool> playSong(Song song) async {
    if (!song.playable) {
      return false;
    }

    final item = MediaItem(
      id: song.uri!,
      title: song.title,
      artist: song.category,
      duration: _parseDuration(song.duration),
    );
    mediaItem.add(item);
    await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
    await _player.play();
    return true;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;

  bool get isPlaying => _player.playing;

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    return switch (state) {
      ProcessingState.idle => AudioProcessingState.idle,
      ProcessingState.loading => AudioProcessingState.loading,
      ProcessingState.buffering => AudioProcessingState.buffering,
      ProcessingState.ready => AudioProcessingState.ready,
      ProcessingState.completed => AudioProcessingState.completed,
    };
  }

  Duration? _parseDuration(String duration) {
    final parts = duration.split(':');
    if (parts.length != 2) {
      return null;
    }
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    if (minutes == null || seconds == null) {
      return null;
    }
    return Duration(minutes: minutes, seconds: seconds);
  }
}
