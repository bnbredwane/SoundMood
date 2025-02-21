import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundmood/models/track_model.dart';

class TrackDetailsScreen extends StatefulWidget {
  final Track track;
  const TrackDetailsScreen({Key? key, required this.track}) : super(key: key);

  @override
  State<TrackDetailsScreen> createState() => _TrackDetailsScreenState();
}

class _TrackDetailsScreenState extends State<TrackDetailsScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playTrack();
  }

  Future<void> _playTrack() async {
    try {
      await _audioPlayer.setUrl(widget.track.url);
      _audioPlayer.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.track.name,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Album art
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(widget.track.albumArt),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Track details and controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    widget.track.name,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.track.artist,
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  // Play/Pause Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_isPlaying) {
                          _audioPlayer.pause();
                        } else {
                          _audioPlayer.play();
                        }
                        _isPlaying = !_isPlaying;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1DB954),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Optionally, add a progress bar below (using a StreamBuilder similar to your PlayerScreen)
                  StreamBuilder<Duration>(
                    stream: _audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final total = _audioPlayer.duration ?? Duration.zero;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            _formatDuration(total),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
