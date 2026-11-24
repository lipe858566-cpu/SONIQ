class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.cover,
    required this.genre,
    this.album = '',
    this.artworkUrl,
    this.audioUrl,
    this.lrcPath,
    this.lyrics,
  });

  final String id;
  final String title;
  final String artist;
  final String duration;
  final String cover;
  final String genre;
  final String album;
  final String? artworkUrl;
  final String? audioUrl;
  final String? lrcPath;
  final String? lyrics;

  bool get playable => audioUrl != null && audioUrl!.isNotEmpty;
  String get image => artworkUrl ?? cover;

  Duration get length {
    final parts = duration.split(':');
    if (parts.length != 2) return Duration.zero;
    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;
    return Duration(minutes: minutes, seconds: seconds);
  }

  static String formatSeconds(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class MusicPlaylist {
  MusicPlaylist({
    required this.id,
    required this.title,
    required this.cover,
    required this.trackIds,
    this.description = '',
    this.displayCount,
  });

  final String id;
  final String title;
  final String cover;
  final List<String> trackIds;
  final String description;
  final int? displayCount;

  int get count => displayCount ?? trackIds.length;
}

class MusicGenre {
  const MusicGenre(this.name, this.cover);
  final String name;
  final String cover;
}
