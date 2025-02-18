import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundmood/models/mood_model.dart';
import 'package:soundmood/models/track_model.dart';
import 'package:soundmood/services/deezer_service.dart';

class PlayerScreen extends StatefulWidget {
  final Mood? selectedMood;
  const PlayerScreen({Key? key, this.selectedMood}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  late PageController _pageController;
  List<Track> _tracks = [];
  int _currentPage = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _pageController = PageController();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected mood changes, reinitialize tracks.
    if (widget.selectedMood?.name != oldWidget.selectedMood?.name) {
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    if (widget.selectedMood == null) {
      setState(() {
        _errorMessage = 'No mood selected.';
        _isLoading = false;
      });
      return;
    }
    try {
      // Choose a random tag from the mood's genres.
      final randomTag = widget.selectedMood!.genres[Random().nextInt(widget.selectedMood!.genres.length)];
      debugPrint('Using tag: $randomTag');

      // Get tracks for the selected tag from Deezer.
      final tracks = await DeezerService.searchTracks(randomTag);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
      // Auto-play the first track.
      if (_tracks.isNotEmpty) {
        _currentPage = 0;
        _playTrack(_tracks[0]);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading music: $e';
        _isLoading = false;
      });
    }
  }

  // Play track at given index using just_audio.
  Future<void> _playTrack(Track track) async {
    try {
      await _audioPlayer.setUrl(track.uri);
      // Automatically play the track if not muted.
      _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  // Called when the PageView page changes.
  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    if (_tracks.isNotEmpty && index < _tracks.length) {
      _playTrack(_tracks[index]);
    }
  }

  // Build a page for each track.
  Widget _buildTrackPage(Track track) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background: album art with gradient overlay.
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(track.albumArt),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Overlay with track details.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mute toggle button.
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(
                      _audioPlayer.playing ? (_audioPlayer.volume == 0 ? Icons.volume_off : Icons.volume_up) : Icons.pause,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      // Toggle mute by setting volume to 0 or restoring it (assume default 1.0)
                      if (_audioPlayer.volume > 0) {
                        _audioPlayer.setVolume(0);
                      } else {
                        _audioPlayer.setVolume(1.0);
                      }
                      setState(() {});
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  track.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  track.artist,
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Display error state.
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializePlayer,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _tracks.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final track = _tracks[index];
          return _buildTrackPage(track);
        },
      ),
    );
  }
}
