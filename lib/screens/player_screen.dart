import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundmood/ai/ai.dart';
import 'package:soundmood/models/mood_model.dart';
import 'package:soundmood/models/track_model.dart';
import 'package:soundmood/services/deezer_service.dart';
import '../widgets/track_detail_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  late PageController _pageController;
  late SharedPreferences _prefs;

  final List<Mood> _availableMoods = [
    Mood('Happy', '🎉', ['pop', 'dance']),
    Mood('Calm', '🧘', ['ambient', 'chill']),
    Mood('Energy', '💥', ['rock', 'hip-hop']),
    Mood('Chill', '🌿', ['lofi']),
    Mood('Romantic', '💖', ['R&B', 'soul']),
    Mood('Sad', '😢', ['sad', 'blues', 'piano', 'ballad']),
  ];

  List<Mood> _selectedMoods = [];
  late Mood _selectedMood;
  List<Track> _tracks = [];
  int _currentPage = 0;
  bool _isLoading = true;
  bool _isMuted = false;
  String _errorMessage = '';
  late AnimationController _moodAnimationController;

  late MoodPreferences _moodPreferences;

  DateTime? _trackStartTime;

  Mood? _currentMood;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _pageController = PageController();
    _moodAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _moodPreferences = MoodPreferences.initial('default');

    _initPreferences().then((_) => _initializePlayer());
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (_prefs.containsKey('moodPreferences')) {
      final data = json.decode(_prefs.getString('moodPreferences')!);
      setState(() => _moodPreferences = MoodPreferences.fromJson(data));
    } else {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'default';
      setState(() => _moodPreferences = MoodPreferences.initial(userId));
    }
  }

  Future<void> _persistMoodPreferences() async {
    await _prefs.setString(
        'moodPreferences', json.encode(_moodPreferences.toJson()));
  }

  void _updatePlayCount(Mood mood) {
    final newCount = (_moodPreferences.playCounts[mood.name] ?? 0) + 1;
    setState(() {
      _moodPreferences.playCounts[mood.name] = newCount;
    });
    _persistMoodPreferences();
  }

  void _trackFavorite(Mood mood) {
    final newCount = (_moodPreferences.favorites[mood.name] ?? 0) + 1;
    setState(() => _moodPreferences.favorites[mood.name] = newCount);
    _adaptCoefficients(mood, true);
    _persistMoodPreferences();
  }

  void _trackSkip(Mood mood) {
    final newCount = (_moodPreferences.skips[mood.name] ?? 0) + 1;
    setState(() => _moodPreferences.skips[mood.name] = newCount);
    _adaptCoefficients(mood, false);
    _persistMoodPreferences();
  }

  void _trackListenDuration(Mood mood, double seconds) {
    final newDuration =
        (_moodPreferences.listenDuration[mood.name] ?? 0) + seconds;
    setState(() => _moodPreferences.listenDuration[mood.name] = newDuration);
    _persistMoodPreferences();
  }

  void _adaptCoefficients(Mood mood, bool wasPositive) {
    setState(() {
      _moodPreferences = MoodRecommender.adaptCoefficients(
        preferences: _moodPreferences,
        selectedMood: mood.name,
        successScore: wasPositive ? 0.8 : 0.2,
      );
    });
    _persistMoodPreferences();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    _moodAnimationController.dispose();
    super.dispose();
  }

  String _getRecommendedTag() {
    if (_selectedMoods.isNotEmpty) {
      return _selectedMoods.first.name.toLowerCase();
    }
    final recommendedMoods = MoodRecommender.getRecommendedMoods(
      preferences: _moodPreferences,
      availableMoods: _availableMoods,
    );
    final mood = recommendedMoods.isNotEmpty
        ? recommendedMoods.first
        : _availableMoods.first;
    return mood.name.toLowerCase();
  }

  Future<void> _initializePlayer() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final recommendedTag = _getRecommendedTag();
      final tracks = await DeezerService.searchTracks(recommendedTag);

      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });

      if (_tracks.isNotEmpty) {
        _currentPage = 0;
        final recommendedMood = _availableMoods.firstWhere(
          (m) => m.name.toLowerCase() == recommendedTag,
          orElse: () => _availableMoods.first,
        );
        _playTrack(_tracks[0], recommendedMood);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading tracks: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _playTrack(Track track, Mood mood) async {
    try {
      _trackStartTime = DateTime.now();
      _currentMood = mood;

      await _audioPlayer.setUrl(track.url);
      _audioPlayer.play();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed &&
            _trackStartTime != null) {
          final duration =
              DateTime.now().difference(_trackStartTime!).inSeconds;
          _trackListenDuration(mood, duration.toDouble());

          _trackStartTime = null;
        }
      });

      _updatePlayCount(mood);
      setState(() => _isPlaying = true);
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  void _onPageChanged(int index) {
    if (_trackStartTime != null && _currentMood != null) {
      final elapsed = DateTime.now().difference(_trackStartTime!).inSeconds;

      _trackListenDuration(_currentMood!, elapsed.toDouble());

      if (elapsed < 5) {
        _trackSkip(_currentMood!);
      }
      _trackStartTime = null;
    }
    setState(() => _currentPage = index);
    if (index < _tracks.length) {
      final recommendedMood = _selectedMoods.isNotEmpty
          ? _selectedMoods.first
          : MoodRecommender.getRecommendedMoods(
              preferences: _moodPreferences,
              availableMoods: _availableMoods,
            ).first;

      final dynamicBoost = MoodRecommender.getDynamicBoost(
          recommendedMood.name, _moodPreferences);
      print('''
Recommendation Factors for ${recommendedMood.name}:
- Favorites: ${_moodPreferences.favorites[recommendedMood.name] ?? 0}
- Skips: ${_moodPreferences.skips[recommendedMood.name] ?? 0}
- Duration: ${_moodPreferences.listenDuration[recommendedMood.name]?.toStringAsFixed(1) ?? '0'}
- Boost: ${dynamicBoost.toStringAsFixed(2)}
    ''');

      _playTrack(_tracks[index], recommendedMood);
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
                          final isSelected =
                              tempSelected.any((m) => m.name == mood.name);
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
                                  tempSelected
                                      .removeWhere((m) => m.name == mood.name);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, tempSelected),
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
        setState(() => _selectedMoods = selected);
        _selectedMood = _selectedMoods.isNotEmpty
            ? _selectedMoods.first
            : Mood('All', '🎶', []);
        _initializePlayer();
      }
    });
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _audioPlayer.setVolume(_isMuted ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
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
                        final user = FirebaseAuth.instance.currentUser;
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
                          loggedInUserId: user?.uid,
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
                        icon:
                            const Icon(Icons.filter_list, color: Colors.white),
                        label: Text(
                          _selectedMoods.isEmpty
                              ? "Recommended"
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
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          Text(_errorMessage, style: const TextStyle(color: Colors.white)),
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
