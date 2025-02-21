import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundmood/models/track_model.dart';

class TrackDetailWidget extends StatelessWidget {
  final Track track;
  final AudioPlayer audioPlayer;
  final bool isPlaying;
  final VoidCallback onTogglePlayPause;

  const TrackDetailWidget({
    Key? key,
    required this.track,
    required this.audioPlayer,
    required this.isPlaying,
    required this.onTogglePlayPause,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Album art background.
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(track.albumArt),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Foreground UI using SafeArea.
        SafeArea(
          child: Column(
            children: [
              // Optional header space.
              const SizedBox(height: 20),
              // Expanded spacer pushes the bottom group down.
              Expanded(child: Container()),
              // Bottom group: track info, progress bar, and controls.
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Centered track info.
                  Text(
                    track.name,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Progress bar & time labels.
                  StreamBuilder<Duration>(
                    stream: audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final total = audioPlayer.duration ?? Duration.zero;
                      final double progress = total.inMilliseconds == 0
                          ? 0
                          : position.inMilliseconds / total.inMilliseconds;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Slider(
                              value: progress.isNaN ? 0 : progress,
                              min: 0,
                              max: 1,
                              onChanged: (value) {
                                final seekPos = value * total.inMilliseconds;
                                audioPlayer.seek(
                                  Duration(milliseconds: seekPos.toInt()),
                                );
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
                  ),
                  const SizedBox(height: 16),
                  // Bottom row of controls.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Like button.
                        IconButton(
                          onPressed: () {
                            // Like logic here.
                          },
                          icon: const Icon(Icons.favorite_border),
                          color: Colors.white,
                          iconSize: 28,
                        ),
                        // Play/Pause button.
                        GestureDetector(
                          onTap: onTogglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1DB954), // Spotify-like green.
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed: () {

                          },
                          icon: const Icon(Icons.share),
                          color: Colors.white,
                          iconSize: 24,
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
