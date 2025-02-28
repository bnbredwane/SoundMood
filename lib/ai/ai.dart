import 'dart:math';

import 'package:soundmood/models/mood_model.dart';

const List<String> moodNames = [
  'Happy',
  'Calm',
  'Energy',
  'Chill',
  'Romantic',
  'Sad'
];

const Map<String, List<double>> baseCoefficients = {
  'Happy': [0.85, 0.05, 0.25, 0.00, 0.10, 0.00],
  'Calm': [0.00, 0.80, 0.00, 0.35, 0.05, 0.15],
  'Energy': [0.30, 0.00, 0.90, 0.10, 0.00, 0.00],
  'Chill': [0.10, 0.40, 0.05, 0.85, 0.00, 0.10],
  'Romantic': [0.15, 0.10, 0.00, 0.00, 0.95, 0.25],
  'Sad': [0.00, 0.20, 0.00, 0.15, 0.30, 0.90],
};

class MoodPreferences {
  final Map<String, int> playCounts;
  final Map<String, int> favorites;
  final Map<String, int> skips;
  final Map<String, double> listenDuration;
  final Map<String, List<double>> coefficients;

  MoodPreferences({
    required this.playCounts,
    required this.favorites,
    required this.skips,
    required this.listenDuration,
    required this.coefficients,
  });

  factory MoodPreferences.initial(String userId) {
    return MoodPreferences(
      playCounts: {},
      favorites: {},
      skips: {},
      listenDuration: {},
      coefficients: _generatePersonalizedCoefficients(userId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playCounts': playCounts,
      'favorites': favorites,
      'skips': skips,
      'listenDuration': listenDuration,
      'coefficients': coefficients.map((k, v) => MapEntry(k, v)),
    };
  }

  factory MoodPreferences.fromJson(Map<String, dynamic> json) {
    return MoodPreferences(
      playCounts: Map<String, int>.from(json['playCounts']),
      favorites: Map<String, int>.from(json['favorites']),
      skips: Map<String, int>.from(json['skips']),
      listenDuration: Map<String, double>.from(json['listenDuration']),
      coefficients: (json['coefficients'] as Map)
          .map((k, v) => MapEntry(k as String, (v as List).cast<double>())),
    );
  }

  static Map<String, List<double>> _generatePersonalizedCoefficients(
      String userId) {
    final random = Random(userId.hashCode);
    return baseCoefficients.map((mood, coeffs) {
      final personalized = coeffs
          .map((c) => c.clamp(0.1, 0.9) * (0.95 + random.nextDouble() * 0.1))
          .toList();
      final sum = personalized.reduce((a, b) => a + b);
      return MapEntry(mood, personalized.map((c) => c / sum).toList());
    });
  }
}

class MoodRecommender {
  static const _learningRate = 0.15;
  static const _decayFactor = 0.98;

  static List<Mood> getRecommendedMoods({
    required MoodPreferences preferences,
    required List<Mood> availableMoods,
  }) {
    final weightedScores = calculateWeightedScores(preferences);
    final proportions = normalizeScores(weightedScores);

    return availableMoods
        .where((m) => moodNames.contains(m.name))
        .map((mood) {
          final score = calculateMoodScore(
              mood.name, proportions, preferences.coefficients);
          return MapEntry(
              mood, score * getDynamicBoost(mood.name, preferences));
        })
        .sorted((a, b) => b.value.compareTo(a.value))
        .take(2)
        .map((e) => e.key)
        .toList();
  }

  static Map<String, double> calculateWeightedScores(
      MoodPreferences preferences) {
    const weights = {
      'play': 1.0,
      'favorite': 1.5,
      'skip': -0.7,
      'duration': 0.8,
    };

    return Map.fromEntries(moodNames.map((mood) {
      final play = preferences.playCounts[mood] ?? 0;
      final favorite = preferences.favorites[mood] ?? 0;
      final skip = preferences.skips[mood] ?? 0;
      final duration = preferences.listenDuration[mood] ?? 0;

      final score = play * weights['play']! +
          favorite * weights['favorite']! +
          skip * weights['skip']! +
          duration * weights['duration']!;

      return MapEntry(mood, score);
    }));
  }

  static Map<String, double> normalizeScores(Map<String, double> scores) {
    final total = scores.values.sum();
    return total == 0
        ? {for (var m in moodNames) m: 1 / moodNames.length}
        : scores.map((k, v) => MapEntry(k, v / total));
  }

  static double calculateMoodScore(
    String mood,
    Map<String, double> proportions,
    Map<String, List<double>> coefficients,
  ) {
    return coefficients[mood]!.asMap().entries.fold(0.0,
        (sum, entry) => sum + entry.value * proportions[moodNames[entry.key]]!);
  }

  static double getDynamicBoost(String mood, MoodPreferences preferences) {
    final recentFavorites = preferences.favorites[mood] ?? 0;
    final recentSkips = preferences.skips[mood] ?? 0;
    final duration = preferences.listenDuration[mood] ?? 0;

    double boost = 1.0;
    if (recentFavorites > 2) boost *= pow(1.2, recentFavorites);
    if (recentSkips > 1) boost *= pow(0.85, recentSkips);
    if (duration > 15) boost *= 0.5;
    if (duration > 30) boost *= 1.15;
    return boost;
  }

  static MoodPreferences adaptCoefficients({
    required MoodPreferences preferences,
    required String selectedMood,
    required double successScore,
  }) {
    final newCoefficients = Map.of(preferences.coefficients);
    final currentCoeffs = List.of(newCoefficients[selectedMood]!);
    final targetIndex = moodNames.indexOf(selectedMood);

    currentCoeffs[targetIndex] =
        (currentCoeffs[targetIndex] + _learningRate * successScore)
            .clamp(0.1, 0.9);

    for (int i = 0; i < currentCoeffs.length; i++) {
      if (i != targetIndex) {
        currentCoeffs[i] = (currentCoeffs[i] * _decayFactor).clamp(0.05, 0.8);
      }
    }

    final sum = currentCoeffs.sum();
    newCoefficients[selectedMood] = currentCoeffs.map((c) => c / sum).toList();

    return MoodPreferences(
      playCounts: Map.of(preferences.playCounts),
      favorites: Map.of(preferences.favorites),
      skips: Map.of(preferences.skips),
      listenDuration: Map.of(preferences.listenDuration),
      coefficients: newCoefficients,
    );
  }
}

extension SumIterable on Iterable<double> {
  double sum() => fold(0.0, (a, b) => a + b);
}

extension Sorted<T> on Iterable<T> {
  Iterable<T> sorted(int Function(T a, T b) compare) => toList()..sort(compare);
}

extension MapGet on Map<String, double> {
  double get(String key) => this[key] ?? 0.0;
}
