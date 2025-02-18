import 'package:flutter/material.dart';
import '../models/track_model.dart';

class TrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onPlay;

  const TrackCard({super.key, required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(track.albumArt),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Text(
                track.name,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                track.artist,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                iconSize: 50,
                icon: const Icon(Icons.play_circle_filled),
                onPressed: onPlay,
              ),
            ],
          ),
        ),
      ],
    );
  }
}