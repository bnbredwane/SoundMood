import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundmood/models/track_model.dart';
import 'package:soundmood/services/deezer_service.dart';
import 'track_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Track> _recentSearches = [];
  List<Track> _tracks = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Load recent searches from Firestore for the current user.
  Future<void> _loadRecentSearches() async {
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
        _recentSearches = (doc.data()!["recentSearches"] as List<dynamic>)
            .map((json) => Track.fromJson(json as Map<String, dynamic>))
            .toList();
      });
    }
  }

  // Update recent searches in Firestore when a track is selected.
  Future<void> _updateRecentSearches(Track track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Check if the track is already in recent searches.
    bool exists = _recentSearches.any((t) => t.id == track.id);
    if (!exists) {
      setState(() {
        _recentSearches.insert(0, track);
        // Optionally limit to 10 items.
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.sublist(0, 10);
        }
      });
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
          {"recentSearches": _recentSearches.map((t) => t.toJson()).toList()},
          SetOptions(merge: true));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _searchTracks(String query) async {
    // If query is empty, clear search results.
    if (query.isEmpty) {
      setState(() {
        _tracks = [];
        _errorMessage = '';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
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
  }

  // When tapping a recent search item, navigate to the track details.
  void _selectRecentSearch(Track track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackDetailsScreen(track: track),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Build a vertical list of recent searches.
  Widget _buildRecentSearches() {
    if (_recentSearches.isEmpty) {
      return const Center(
        child: Text(
          "No recent searches",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return ListView.separated(
      itemCount: _recentSearches.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white24),
      itemBuilder: (context, index) {
        final track = _recentSearches[index];
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
          onTap: () => _selectRecentSearch(track),
        );
      },
    );
  }

  // Build search results list.
  Widget _buildResults() {
    if (_tracks.isEmpty && !_isLoading) {
      return const Center(
        child: Text("No results", style: TextStyle(color: Colors.white70)),
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
            // Update recent searches when a result is tapped.
            await _updateRecentSearches(track);
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

  @override
  Widget build(BuildContext context) {
    // When search field is empty, show recent searches; otherwise, show results.
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
            TextField(
              controller: _searchController,
              onChanged: _searchTracks,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for tracks, artists, or genres',
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
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            Expanded(
              child: showRecent ? _buildRecentSearches() : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }
}
