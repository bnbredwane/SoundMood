import 'package:flutter/material.dart';
import 'package:soundmood/models/track_model.dart';
import '../managers/favorites_manager.dart';
import '../utils/constants.dart';

class TrackCard extends StatelessWidget {
  final Track track;
  final double volume;
  final ValueChanged<double> onVolumeChanged;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const TrackCard({
    super.key,
    required this.track,
    required this.volume,
    required this.onVolumeChanged,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(track.albumArt),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  onPressed: () {},
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.artist,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: volume,
                          onChanged: onVolumeChanged,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.white24,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          volume > 0
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        onPressed: () => onVolumeChanged(volume > 0 ? 0 : 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Favorite (like) button using FutureBuilder.
                      FutureBuilder<bool>(
                        future: FavoritesManager.isFavorite(track),
                        builder: (context, snapshot) {
                          bool isFav = snapshot.data ?? false;
                          return IconButton(
                            onPressed: () async {
                              await FavoritesManager.toggleFavorite(track);
                              // Optionally, trigger a rebuild.
                              (context as Element).markNeedsBuild();
                            },
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                            ),
                            color: Colors.white,
                            iconSize: 28,
                          );
                        },
                      ),
                      // Play/Pause button.
                      GestureDetector(
                        onTap: onPlayPause,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        color: Colors.white,
                        iconSize: 32,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
