class Mood {
  final String name;
  final String emoji;
  final List<String> genres; // These serve as tag names for Last.fm

  Mood(this.name, this.emoji, this.genres);

  factory Mood.fromJson(Map<String, dynamic> json) {
    return Mood(
      json['name'],
      json['emoji'],
      List<String>.from(json['genres']),
    );
  }
}
