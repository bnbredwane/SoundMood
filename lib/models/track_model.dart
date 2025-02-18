class Track {
  final String id;
  final String name;
  final String artist;
  final String albumArt;
  final String uri;
  final int duration;

  Track({
    required this.id,
    required this.name,
    required this.artist,
    required this.albumArt,
    required this.uri,
    required this.duration,
  });

  // Factory constructor to create a Track from Deezer JSON.
  // Deezer returns:
  // - 'id' (an integer)
  // - 'title' (the track title)
  // - 'duration' (in seconds)
  // - 'preview' (URL for a 30-second preview)
  // - 'album' (an object with cover images, e.g. 'cover_big')
  // - 'artist' (an object with the artist's name)
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
      uri: json['preview'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}
