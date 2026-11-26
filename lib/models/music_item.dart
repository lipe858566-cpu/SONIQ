class MusicItem {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String? thumbnail;
  final String url;
  String? audioStreamUrl;

  MusicItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.thumbnail,
    required this.url,
    this.audioStreamUrl,
  });
}
