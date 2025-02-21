class Track {
  final String id;
  final String name;
  final String artist;
  final String albumArt;
  final String url;
  final int duration;

  Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumArt,
    required this.url,
    required this.duration,
  });

  factory Track.fromDeezerJson(Map<String, dynamic> json) {
    String albumArt = '';
    if (json['album'] != null) {
      albumArt = json['album']['cover_big'] ?? '';
    }
    final artistName = json['artist'] != null ? json['artist']['name'] : '';
    return Track(
      id: json['id'].toString(),
      name: json['title'] ?? '',
      artist: artistName,
      albumArt: albumArt,
      url: json['preview'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      artist: json['artist'] ?? '',
      albumArt: json['albumArt'] ?? '',
      url: json['url'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}
