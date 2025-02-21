import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:soundmood/models/mood_model.dart';
import 'package:soundmood/models/track_model.dart';
import 'package:soundmood/services/deezer_service.dart';
import '../widgets/track_detail_widget.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _volume = 1.0;
  late PageController _pageController;


  final List<Mood> _availableMoods = [
    Mood('Happy', '🎉', ['pop', 'dance']),
    Mood('Calm', '🧘', ['ambient', 'chill']),
    Mood('Energy', '💥', ['rock', 'hip-hop']),
    Mood('Chill', '🌿', ['lofi']),
    Mood('Romantic', '💖', ['R&B', 'soul']),
    Mood('Sad', '😢', ['sad', 'blues', 'piano','ballad']),

  ];


  List<Mood> _selectedMoods = [];


  late Mood _selectedMood;

  List<Track> _tracks = [];
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isMuted = false;
  String _errorMessage = '';

  late AnimationController _moodAnimationController;

  @override
  void initState() {
    super.initState();

    _selectedMood = Mood('All', '🎶', []);
    _audioPlayer = AudioPlayer();
    _pageController = PageController();
    _moodAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializePlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    _moodAnimationController.dispose();
    super.dispose();
  }


  String _getRandomTag() {

    if (_selectedMoods.isNotEmpty) {
      final mood = _selectedMoods[Random().nextInt(_selectedMoods.length)];
      return mood.genres[Random().nextInt(mood.genres.length)];
    }

    final mood = _availableMoods[Random().nextInt(_availableMoods.length)];
    return mood.genres[Random().nextInt(mood.genres.length)];
  }


  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      final randomTag = _getRandomTag();
      final tracks = await DeezerService.searchTracks(randomTag);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
      if (_tracks.isNotEmpty) {
        _currentPage = 0;
        _playTrack(_tracks[0]);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading tracks: $e';
        _isLoading = false;
      });
    }
  }


  Future<void> _playTrack(Track track) async {
    try {
      await _audioPlayer.setUrl(track.url);
      _audioPlayer.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }


  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    if (index < _tracks.length) {
      _playTrack(_tracks[index]);
    }
  }


  void _openMoodSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (context) {

        List<Mood> tempSelected = List.from(_selectedMoods);
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Select Moods",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _availableMoods.length,
                        itemBuilder: (context, index) {
                          final mood = _availableMoods[index];
                          final isSelected = tempSelected
                              .any((m) => m.name == mood.name);
                          return CheckboxListTile(
                            activeColor: Colors.purpleAccent,
                            checkColor: Colors.white,
                            title: Text(
                              "${mood.emoji} ${mood.name}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            value: isSelected,
                            onChanged: (value) {
                              setStateModal(() {
                                if (value == true) {
                                  tempSelected.add(mood);
                                } else {
                                  tempSelected.removeWhere(
                                          (m) => m.name == mood.name);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, tempSelected);
                      },
                      child: const Text("Apply"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((selected) {
      if (selected != null) {
        setState(() {
          _selectedMoods = selected;
        });

        if (_selectedMoods.isNotEmpty) {
          _selectedMood = _selectedMoods.first;
        } else {

          _selectedMood = Mood('All', '🎶', []);
        }
        _initializePlayer();
      }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : _errorMessage.isNotEmpty
          ? _buildErrorState()
          : Stack(
        children: [

          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _tracks.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return TrackDetailWidget(
                track: _tracks[index],
                audioPlayer: _audioPlayer,
                isPlaying: _isPlaying,
                onTogglePlayPause: () {
                  setState(() {
                    if (_isPlaying) {
                      _audioPlayer.pause();
                    } else {
                      _audioPlayer.play();
                    }
                    _isPlaying = !_isPlaying;
                  });
                },
              );
            },
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 16,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: _openMoodSelection,
              icon: const Icon(
                Icons.filter_list,
                color: Colors.white,
              ),
              label: Text(
                _selectedMoods.isEmpty
                    ? "All Moods"
                    : "${_selectedMoods.length} Selected",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 16,
            child: IconButton(
              icon: Icon(
                _isMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _toggleMute,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializePlayer,
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}
