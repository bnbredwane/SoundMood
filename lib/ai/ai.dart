import 'package:soundmood/models/mood_model.dart';

const List<String> moodNames = [
  'Happy',
  'Calm',
  'Energy',
  'Chill',
  'Romantic',
  'Sad'
];

Map<String, double> getMoodProportions(Map<String, int> moodPlayCounts) {
  int totalPlays =
      moodNames.fold(0, (sum, mood) => sum + (moodPlayCounts[mood] ?? 0));
  if (totalPlays == 0) {
    return {for (var m in moodNames) m: 1 / moodNames.length};
  }
  return {for (var m in moodNames) m: (moodPlayCounts[m] ?? 0) / totalPlays};
}

List<Mood> getRecommendedMoods6(
    Map<String, int> moodPlayCounts, List<Mood> availableMoods) {
  Map<String, double> proportions = getMoodProportions(moodPlayCounts);

  Map<String, List<double>> moodCoefficients = {
    'Happy': [0.9, 0.1, 0.3, 0.0, 0.0, 0.0],
    'Calm': [0.0, 0.9, 0.0, 0.4, 0.0, 0.0],
    'Energy': [0.3, 0.0, 0.9, 0.1, 0.0, 0.0],
    'Chill': [0.3, 0.5, 0.1, 0.9, 0.0, 0.0],
    'Romantic': [0.4, 0.1, 0.0, 0.0, 0.9, 0.3],
    'Sad': [0.0, 0.0, 0.0, 0.0, 0.1, 0.9],
  };

  List<MapEntry<Mood, double>> moodScores = [];
  for (var mood in availableMoods) {
    if (!moodNames.contains(mood.name)) continue;
    List<double> coeff =
        moodCoefficients[mood.name] ?? [0.5, 0.5, 0.5, 0.5, 0.5, 0.5];
    double score = 0;
    for (int i = 0; i < moodNames.length; i++) {
      score += coeff[i] * (proportions[moodNames[i]] ?? 0);
    }
    if (score > 0.7) score *= 1.1;
    print("Mood: ${mood.name} - Score: ${score.toStringAsFixed(2)}");
    moodScores.add(MapEntry(mood, score));
  }
  moodScores.sort((a, b) => b.value.compareTo(a.value));
  return moodScores.take(2).map((e) => e.key).toList();
}
