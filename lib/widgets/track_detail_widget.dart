import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundmood/models/track_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class TrackDetailWidget extends StatelessWidget {
  static const _favoriteColor = Colors.red;
  static const _controlButtonColor = Color(0xFF1DB954);
  static const _gradientOpacity = 0.4;
  static const _iconSize = 28.0;
  static const _playButtonSize = 32.0;

  final Track track;
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final VoidCallback onTogglePlayPause;
  final String? loggedInUserId;

  const TrackDetailWidget({
    super.key,
    required this.track,
    required this.audioPlayer,
    required this.isPlaying,
    required this.onTogglePlayPause,
    required this.loggedInUserId,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    try {
      final userDoc =
          FirebaseFirestore.instance.collection("users").doc(loggedInUserId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final doc = await transaction.get(userDoc);
        final data = doc.data() as Map<String, dynamic>?;
        final favorites =
            List<Map<String, dynamic>>.from(data?['favorites'] ?? []);

        final index = favorites.indexWhere((fav) => fav['id'] == track.id);
        if (index != -1) {
          favorites.removeAt(index);
        } else {
          favorites.add({
            'id': track.id,
            'name': track.name,
            'artist': track.artist,
            'albumArt': track.albumArt,
            'url': track.url,
            'duration': track.duration,
          });
        }

        transaction.set(
            userDoc, {'favorites': favorites}, SetOptions(merge: true));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
        ),
      );
    }
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text("You need to login to save favorites"),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    if (loggedInUserId == null) {
      return IconButton(
        icon: const Icon(Icons.favorite_border, color: Colors.white),
        onPressed: () => _showLoginDialog(context),
        iconSize: _iconSize,
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(loggedInUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final favorites = data?['favorites'] as List? ?? [];
        final isFavorite = favorites
            .any((fav) => (fav as Map<String, dynamic>)['id'] == track.id);

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _favoriteColor,
          ),
          onPressed: () => _toggleFavorite(context),
          iconSize: _iconSize,
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = audioPlayer.duration ?? Duration.zero;
        final progress = total.inMilliseconds == 0
            ? 0.0
            : position.inMilliseconds / total.inMilliseconds;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Slider(
                value: progress.clamp(0.0, 1.0),
                min: 0,
                max: 1,
                onChanged: (value) async {
                  try {
                    await audioPlayer.seek(
                      Duration(
                          milliseconds: (value * total.inMilliseconds).toInt()),
                    );
                  } catch (e) {
                    debugPrint('Error seeking track: $e');
                  }
                },
                activeColor: Colors.white,
                inactiveColor: Colors.white54,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(total),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(track.albumArt),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(_gradientOpacity),
                Colors.black.withOpacity(_gradientOpacity * 2),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(child: Container()),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  _buildProgressIndicator(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildFavoriteButton(context),
                        GestureDetector(
                          onTap: onTogglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: _controlButtonColor,
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: _playButtonSize,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Share.share(
                            'Check out "${track.name}" by ${track.artist} '
                            'on SoundMood: ${track.url}',
                          ),
                          icon: const Icon(Icons.share),
                          color: Colors.white,
                          iconSize: _iconSize,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
