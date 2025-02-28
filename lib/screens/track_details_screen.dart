import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soundmood/models/track_model.dart';
import '../widgets/track_detail_widget.dart';

class TrackDetailsScreen extends StatefulWidget {
  final Track track;
  const TrackDetailsScreen({super.key, required this.track});

  @override
  State<TrackDetailsScreen> createState() => _TrackDetailsScreenState();
}

class _TrackDetailsScreenState extends State<TrackDetailsScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isMuted = false;

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
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _toggleMute() {
    if (_isMuted) {
      _audioPlayer.setVolume(1.0);
    } else {
      _audioPlayer.setVolume(0.0);
    }
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isMuted ? Icons.volume_off : Icons.volume_up,
              color: Colors.white,
            ),
            onPressed: _toggleMute,
          ),
        ],
      ),
      body: TrackDetailWidget(
        track: widget.track,
        audioPlayer: _audioPlayer,
        isPlaying: _isPlaying,
        onTogglePlayPause: _togglePlayPause,
        loggedInUserId: loggedInUserId,
      ),
    );
  }
}
