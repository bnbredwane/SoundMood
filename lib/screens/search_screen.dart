import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundmood/models/track_model.dart';
import 'package:soundmood/screens/profile_screen.dart';
import 'package:soundmood/services/deezer_service.dart';
import 'track_details_screen.dart';

enum SearchMode { tracks, users }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Recent searches for tracks and profiles.
  List<Track> _recentTracks = [];
  List<Map<String, dynamic>> _recentProfiles = [];

  // Search results for tracks and users.
  List<Track> _tracks = [];
  List<DocumentSnapshot> _users = [];

  bool _isLoading = false;
  String _errorMessage = '';
  SearchMode _searchMode = SearchMode.tracks;

  // LOAD RECENTS FOR TRACKS
  Future<void> _loadRecentTracks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!["recentSearches"] != null) {
      setState(() {
        _recentTracks = (doc.data()!["recentSearches"] as List<dynamic>)
            .map((json) => Track.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    }
  }

  // UPDATE RECENTS FOR TRACKS
  Future<void> _updateRecentTracks(Track track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    bool exists = _recentTracks.any((t) => t.id == track.id);
    if (!exists) {
      setState(() {
        _recentTracks.insert(0, track);
        if (_recentTracks.length > 10) {
          _recentTracks = _recentTracks.sublist(0, 10);
        }
      });
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
          {"recentSearches": _recentTracks.map((t) => t.toJson()).toList()},
          SetOptions(merge: true));
    }
  }

  // LOAD RECENTS FOR PROFILES
  Future<void> _loadRecentProfiles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    if (doc.exists &&
        doc.data() != null &&
        doc.data()!["recentProfileSearches"] != null) {
      setState(() {
        _recentProfiles = List<Map<String, dynamic>>.from(
            doc.data()!["recentProfileSearches"]);
      });
    }
  }

  // UPDATE RECENTS FOR PROFILES
  Future<void> _updateRecentProfiles(Map<String, dynamic> profileData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    bool exists = _recentProfiles.any((p) => p["uid"] == profileData["uid"]);
    if (!exists) {
      setState(() {
        _recentProfiles.insert(0, profileData);
        if (_recentProfiles.length > 10) {
          _recentProfiles = _recentProfiles.sublist(0, 10);
        }
      });
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "recentProfileSearches": _recentProfiles,
      }, SetOptions(merge: true));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecentTracks();
    _loadRecentProfiles();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _tracks = [];
        _users = [];
        _errorMessage = '';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    if (_searchMode == SearchMode.tracks) {
      try {
        final results = await DeezerService.searchTracks(query);
        setState(() {
          _tracks = results;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error searching tracks: $e';
          _isLoading = false;
        });
      }
    } else {
      try {
        String lowercaseQuery = query.toLowerCase();
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection("users")
            .where("username_lowercase", isGreaterThanOrEqualTo: lowercaseQuery)
            .where("username_lowercase",
                isLessThanOrEqualTo: lowercaseQuery + "\uf8ff")
            .get();
        setState(() {
          _users =
              snapshot.docs.where((doc) => doc.id != currentUserId).toList();
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Error searching users: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Build track search results.
  Widget _buildTrackResults() {
    if (_tracks.isEmpty && !_isLoading) {
      return const Center(
        child: Text("No tracks found", style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.builder(
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return ListTile(
          leading: Image.network(
            track.albumArt,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 50,
              width: 50,
              color: Colors.grey[800],
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
          ),
          title: Text(track.name, style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(track.artist, style: const TextStyle(color: Colors.white70)),
          onTap: () async {
            await _updateRecentTracks(track);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDetailsScreen(track: track),
              ),
            );
          },
        );
      },
    );
  }

  // Build user search results.
  Widget _buildUserResults() {
    if (_users.isEmpty && !_isLoading) {
      return const Center(
        child: Text("No users found", style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final doc = _users[index];
        final data = doc.data() as Map<String, dynamic>;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: data["profilePic"].toString().startsWith("http")
                ? NetworkImage(data["profilePic"])
                : AssetImage(data["profilePic"]) as ImageProvider,
          ),
          title: Text(data["username"],
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(data["email"] ?? "",
              style: const TextStyle(color: Colors.white70)),
          onTap: () async {
            await _updateRecentProfiles({
              "uid": doc.id,
              "username": data["username"],
              "email": data["email"],
              "profilePic": data["profilePic"],
            });
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: doc.id,
                  isCurrentUser:
                      FirebaseAuth.instance.currentUser?.uid == doc.id,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build recent track searches.
  Widget _buildRecentTrackSearches() {
    if (_recentTracks.isEmpty) {
      return const Center(
        child: Text("No recent track searches",
            style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.separated(
      itemCount: _recentTracks.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        final track = _recentTracks[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              track.albumArt,
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 50,
                width: 50,
                color: Colors.grey[800],
                child: const Icon(Icons.music_note, color: Colors.white),
              ),
            ),
          ),
          title: Text(track.name, style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(track.artist, style: const TextStyle(color: Colors.white70)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDetailsScreen(track: track),
              ),
            );
          },
        );
      },
    );
  }

  // Build recent profile searches.
  Widget _buildRecentProfileSearches() {
    if (_recentProfiles.isEmpty) {
      return const Center(
        child: Text("No recent profile searches",
            style: TextStyle(color: Colors.white70)),
      );
    }
    return ListView.separated(
      itemCount: _recentProfiles.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        final profile = _recentProfiles[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: profile["profilePic"].toString().startsWith("http")
                ? NetworkImage(profile["profilePic"])
                : AssetImage(profile["profilePic"]) as ImageProvider,
          ),
          title: Text(profile["username"],
              style: const TextStyle(color: Colors.white)),
          subtitle: Text(profile["email"] ?? "",
              style: const TextStyle(color: Colors.white70)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: profile["uid"],
                  isCurrentUser:
                      FirebaseAuth.instance.currentUser?.uid == profile["uid"],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("Tracks", style: TextStyle(color: Colors.white)),
          selected: _searchMode == SearchMode.tracks,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _searchMode = SearchMode.tracks;
                _searchController.clear();
                _tracks = [];
                _users = [];
              });
            }
          },
          selectedColor: Colors.deepPurpleAccent,
          backgroundColor: Colors.white10,
        ),
        const SizedBox(width: 16),
        ChoiceChip(
          label: const Text("Users", style: TextStyle(color: Colors.white)),
          selected: _searchMode == SearchMode.users,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _searchMode = SearchMode.users;
                _searchController.clear();
                _tracks = [];
                _users = [];
              });
            }
          },
          selectedColor: Colors.deepPurpleAccent,
          backgroundColor: Colors.white10,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showRecent = _searchController.text.isEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Search", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildModeToggle(),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (query) {
                if (query.isEmpty) {
                  setState(() {}); // triggers display of recents
                } else {
                  _search(query);
                }
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _searchMode == SearchMode.tracks
                    ? 'Search for tracks, artists, or genres'
                    : 'Search for users',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            if (_errorMessage.isNotEmpty)
              Center(
                  child: Text(_errorMessage,
                      style: const TextStyle(color: Colors.white))),
            Expanded(
              child: _searchMode == SearchMode.tracks
                  ? (showRecent
                      ? _buildRecentTrackSearches()
                      : _buildTrackResults())
                  : (showRecent
                      ? _buildRecentProfileSearches()
                      : _buildUserResults()),
            ),
          ],
        ),
      ),
    );
  }
}
