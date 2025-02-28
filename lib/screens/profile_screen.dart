import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundmood/components/custom_scroll.dart';
import 'package:soundmood/managers/follow_manager.dart'; // Utilise vos fonctions followUser et unfollowUser depuis follow_manager
import 'auth_screen.dart';
import 'track_details_screen.dart';
import 'package:soundmood/models/track_model.dart';

class UserProfileScreen extends StatefulWidget {
  /// userId correspond à l'UID du profil à afficher.
  /// Si isCurrentUser vaut true, on affiche le profil du propriétaire et on propose « Edit Profile ».
  final String userId;
  final bool isCurrentUser;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isFollowing = false;

  // Permet de basculer le statut de follow pour un utilisateur
  void _toggleFollow(String targetUserId) async {
    if (isFollowing) {
      await unfollowUser(
          targetUserId); // Fonction définie dans follow_manager.dart
    } else {
      await followUser(targetUserId);
    }
    setState(() {
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        actions: [
          if (widget.isCurrentUser)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Si le profil affiché n'est pas celui de l'utilisateur courant,
          // on met à jour le statut de follow
          if (!widget.isCurrentUser) {
            final currentUserId = FirebaseAuth.instance.currentUser!.uid;
            List followers = data["followers"] ?? [];
            if (followers.contains(currentUserId) != isFollowing) {
              // On met à jour le booléen de manière asynchrone
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  isFollowing = followers.contains(currentUserId);
                });
              });
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _getProfileImage(data["profilePic"]),
                ),
                const SizedBox(height: 16),
                Text(
                  data["username"] ?? "User",
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  data["email"] ?? "",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                _SocialStats(
                  followers: data["followers"] != null
                      ? (data["followers"] as List).length
                      : 0,
                  following: data["following"] != null
                      ? (data["following"] as List).length
                      : 0,
                ),
                const SizedBox(height: 20),
                // Si c'est le profil du propriétaire, on affiche « Edit Profile »
                // Sinon, on affiche le bouton Follow/Unfollow
                widget.isCurrentUser
                    ? ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/editprofile');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Edit Profile",
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {
                          _toggleFollow(widget.userId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? Colors.grey
                              : Colors.blue, // couleur selon le statut
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          isFollowing ? "Unfollow" : "Follow",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Favorite Music",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFavorites(data),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construit la liste des musiques favorites à partir des données utilisateur
  Widget _buildFavorites(Map<String, dynamic> data) {
    if (data["favorites"] == null) {
      return const Text("No favorites yet",
          style: TextStyle(color: Colors.white70));
    }
    final List favorites = data["favorites"] as List<dynamic>;
    if (favorites.isEmpty) {
      return const Text("No favorites yet",
          style: TextStyle(color: Colors.white70));
    }
    List<Track> tracks = favorites.map((fav) => Track.fromJson(fav)).toList();

    return SizedBox(
      height: 220,
      child: ScrollConfiguration(
        behavior: MyCustomScrollBehavior(),
        child: PageView.builder(
          padEnds: false, // This disables the automatic left/right padding.
          controller: PageController(viewportFraction: 0.3),
          itemCount: tracks.length,
          itemBuilder: (context, index) => _TrackItem(track: tracks[index]),
        ),
      ),
    );
  }

  ImageProvider _getProfileImage(String path) {
    if (path.startsWith("http")) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }
}

class _SocialStats extends StatelessWidget {
  final int followers;
  final int following;
  const _SocialStats(
      {required this.followers, required this.following, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(value: followers, label: "Followers"),
        const SizedBox(width: 40),
        _StatItem(value: following, label: "Following"),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  const _StatItem({required this.value, required this.label, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _TrackItem extends StatelessWidget {
  final Track track;
  const _TrackItem({required this.track, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the TrackDetailsScreen when tapped.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TrackDetailsScreen(track: track),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              track.albumArt,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 150,
                width: 150,
                color: Colors.grey[800],
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 150,
            child: Text(
              track.name,
              style: const TextStyle(color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              track.artist,
              style: const TextStyle(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
