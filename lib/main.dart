import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:soundmood/models/mood_model.dart';
import 'package:soundmood/screens/player_screen.dart';
import 'package:soundmood/screens/search_screen.dart';
import 'package:soundmood/screens/profile_screen.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');
  runApp(const SoundMoodApp());
}

class SoundMoodApp extends StatelessWidget {
  const SoundMoodApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundMood',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Define moods
  final List<Mood> moods = [
    Mood('Happy', '🎉', ['pop', 'dance', 'electronic']),
    Mood('Calm', '🧘', ['ambient', 'classical', 'jazz']),
    Mood('Motivated', '💪', ['rock', 'metal', 'workout']),
    Mood('Sad', '😢', ['blues', 'sad', 'piano']),
  ];

  // Initially selected mood.
  Mood _selectedMood = Mood('Happy', '🎉', ['pop', 'dance', 'electronic']);

  int _currentIndex = 0;

  // Screens for the bottom nav; only the PlayerScreen uses the selected mood.
  List<Widget> get _screens => [
    PlayerScreen(selectedMood: _selectedMood),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  // Update the mood
  void _onMoodSelected(Mood mood) {
    setState(() {
      _selectedMood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoundMood'),
        backgroundColor: Colors.black,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: MoodSelector(
            moods: moods,
            selectedMood: _selectedMood,
            onMoodSelected: _onMoodSelected,
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// A custom widget for mood selection. It displays a horizontally scrollable list.
class MoodSelector extends StatelessWidget {
  final List<Mood> moods;
  final Mood selectedMood;
  final ValueChanged<Mood> onMoodSelected;

  const MoodSelector({
    Key? key,
    required this.moods,
    required this.selectedMood,
    required this.onMoodSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: Colors.grey[900],
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final mood = moods[index];
          final isSelected = mood.name == selectedMood.name;
          return GestureDetector(
            onTap: () => onMoodSelected(mood),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.greenAccent[700] : Colors.grey[800],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(mood.name, style: const TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
