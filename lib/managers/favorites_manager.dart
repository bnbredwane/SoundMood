import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:soundmood/models/track_model.dart';

class FavoritesManager {
  static Future<void> toggleFavorite(Track track) async {
    final userDoc =
        FirebaseFirestore.instance.collection("users").doc("currentUser");
    final doc = await userDoc.get();
    List<dynamic> favorites = doc.data()?["favorites"] ?? [];
    final exists = favorites.any((fav) => fav["id"] == track.id);
    if (exists) {
      favorites.removeWhere((fav) => fav["id"] == track.id);
    } else {
      favorites.add({
        "id": track.id,
        "name": track.name,
        "artist": track.artist,
        "albumArt": track.albumArt,
        "url": track.url,
        "duration": track.duration,
      });
    }
    await userDoc.update({"favorites": favorites});
  }

  static Future<bool> isFavorite(Track track) async {
    final userDoc =
        FirebaseFirestore.instance.collection("users").doc("currentUser");
    final doc = await userDoc.get();
    List<dynamic> favorites = doc.data()?["favorites"] ?? [];
    return favorites.any((fav) => fav["id"] == track.id);
  }

  static Stream<DocumentSnapshot> getFavoritesStream(String userId) {
    final userDoc = FirebaseFirestore.instance.collection("users").doc(userId);
    return userDoc.snapshots();
  }
}
