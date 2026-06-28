class Song {
  const Song({
    required this.title,
    required this.meta,
    required this.duration,
    required this.size,
    this.uri,
    this.favorite = false,
  });

  final String title;
  final String meta;
  final String duration;
  final String size;
  final String? uri;
  final bool favorite;

  String get category {
    final parts = meta.split(' / ');
    return parts.isEmpty ? 'Music' : parts.last;
  }

  bool get playable => uri != null && uri!.trim().isNotEmpty;

  Song copyWith({
    String? title,
    String? meta,
    String? duration,
    String? size,
    String? uri,
    bool? favorite,
  }) {
    return Song(
      title: title ?? this.title,
      meta: meta ?? this.meta,
      duration: duration ?? this.duration,
      size: size ?? this.size,
      uri: uri ?? this.uri,
      favorite: favorite ?? this.favorite,
    );
  }

  factory Song.fromMap(Map<Object?, Object?> map) {
    return Song(
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? map['title']! as String
          : '未知音频',
      meta: (map['meta'] as String?)?.trim().isNotEmpty == true
          ? map['meta']! as String
          : '本机音乐 / Music',
      duration: (map['duration'] as String?)?.trim().isNotEmpty == true
          ? map['duration']! as String
          : '--:--',
      size: (map['size'] as String?)?.trim().isNotEmpty == true
          ? map['size']! as String
          : '未知大小',
      uri: map['uri'] as String?,
    );
  }
}
