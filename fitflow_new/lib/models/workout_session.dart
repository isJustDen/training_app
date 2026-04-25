//models/workout_session.dart

// МОДЕЛЬ СОХРАНЁННОЙ СЕССИИ ТРЕНИРОВКИ
class WorkoutSession{
  final String templateId;
  final DateTime startedAt;

  final Map<String, List<Map<String, dynamic>>> completedSets; // Пррогресс каждого упражнения:

  final Map<String, double> currentWeights; // Текущий вес каждого упражнения

  const WorkoutSession ({
    required this.templateId,
    required this.startedAt,
    required this.completedSets,
    required this.currentWeights,
});

  // СЕРИАЛИЗАЦИЯ → JSON для сохранения в SharedPreferences
  Map<String, dynamic> toMap() => {
    'templateId': templateId,
    'startedAt' : startedAt.toIso8601String(),
    'completedSets': completedSets,
    'currentWeights': currentWeights.map((k, v) => MapEntry(k, v)),
  };

  // ДЕСЕРИАЛИЗАЦИЯ ← JSON при загрузке
  factory WorkoutSession.fromMap(Map<String, dynamic> map){
    final rawSets = map ['completedSets'] as Map<String, dynamic>;
    final completedSets = rawSets.map((key, value) =>
    MapEntry(key, (value as List).cast<Map<String, dynamic>>()),
    );

    final rawWeights = map['currentWeights'] as Map<String, dynamic>;
    final currentWeights = rawWeights.map((k, v) => MapEntry(k, (v as num).toDouble()),
    );

    return WorkoutSession(
        templateId: map['templateId'],
        startedAt: DateTime.parse(map['startedAt']),
        completedSets: completedSets,
        currentWeights: currentWeights
    );
  }

  // ПРОВЕРКА — есть ли реальный прогресс (хоть один подход)
  bool get hasProgress => completedSets.values.any((sets) => sets.isNotEmpty);
}