import 'package:flutter/material.dart';
import '../models/mood_model.dart';
import '../widgets/mood_card.dart';

class MoodSelectionScreen extends StatelessWidget {
  final List<Mood> moods = [
    Mood('Happy', '🎉', ['pop', 'dance', 'electronic']),
    Mood('Calm', '🧘', ['ambient', 'classical', 'jazz']),
    Mood('Motivated', '💪', ['rock', 'metal', 'workout']), // Note: changed 'work-out' to 'workout'
    Mood('Sad', '😢', ['blues', 'sad', 'piano']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling today?'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: moods.length,
        itemBuilder: (context, index) => MoodCard(
          mood: moods[index],
          onTap: () => Navigator.pushNamed(
            context,
            '/player',
            arguments: moods[index],
          ),
        ),
      ),
    );
  }
}
