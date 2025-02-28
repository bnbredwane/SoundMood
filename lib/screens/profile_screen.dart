import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:soundmood/models/track_model.dart';
import 'auth_screen.dart'; // Ensure this is the correct path to your AuthScreen
import 'track_details_screen.dart'; // Import the TrackDetailsScreen

/// Custom scroll behavior to allow dragging with mouse, touch, and trackpad.
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If no user is signed in, display the AuthScreen with the login/signup form.
      return const AuthScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // After signing out, the build method will show the AuthScreen.
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
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
          return _ProfileContent(data: data);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Assuming Profile is the third tab
        backgroundColor: Colors.black,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
        onTap: (index) {
          // Handle navigation based on the selected index.
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/main');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(
                context, '/search'); // Ensure you have a '/search' route
          }
          // Index 2 is Profile (current screen), so do nothing.
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ProfileContent({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final List<Track> favorites = (data["favorites"] as List<dynamic>)
        .map((fav) => Track.fromJson(fav))
        .toList();

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
            followers: data["followers"] ?? 0,
            following: data["following"] ?? 0,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to edit profile.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Edit Profile",
                style: TextStyle(color: Colors.white)),
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
          favorites.isEmpty
              ? const Text("No favorites yet",
                  style: TextStyle(color: Colors.white70))
              : SizedBox(
                  height: 220,
                  child: ScrollConfiguration(
                    behavior: MyCustomScrollBehavior(),
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.6),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) =>
                          _TrackItem(track: favorites[index]),
                    ),
                  ),
                ),
        ],
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
      {required this.followers, required this.following, super.key});

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
  const _StatItem({required this.value, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
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
