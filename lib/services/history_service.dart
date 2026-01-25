//services/history_service.dart

import '../services/storage_service.dart';
import '../models/workout_history.dart';
import '../models/exercise.dart';


// СЕРВИС ДЛЯ ПОЛУЧЕНИЯ ИСТОРИЧЕСКИХ ДАННЫХ ПО УПРАЖНЕНИЯМ
class HistoryService {
  // ПОЛУЧИТЬ ПОСЛЕДНИЕ РЕЗУЛЬТАТЫ ДЛЯ УПРАЖНЕНИЯ
  static Future<List<Exercise>> getLastExerciseResults(
      String exerciseName,
      int limit
      ) async {
    try {
      // ЗАГРУЖАЕМ ВСЮ ИСТОРИЮ
      final history = await StorageService.loadHistory();

      // СОРТИРУЕМ ПО ДАТЕ (САМЫЕ НОВЫЕ ПЕРВЫМИ)
      history.sort((a, b) => b.date.compareTo(a.date));

      // СОБИРАЕМ ВСЕ ВХОЖДЕНИЯ ЭТОГО УПРАЖНЕНИЯ
      List<Exercise> results = [];

      for (var workout in history) {
        for (var exercise in workout.exercises) {
          if (exercise.name == exerciseName) {
            results.add(exercise);

            // ПРЕКРАЩАЕМ, ЕСЛИ НАБРАЛИ НУЖНОЕ КОЛИЧЕСТВО
            if (results.length >= limit) {
              return results;
            }
          }
        }
      }

      return results;
      } catch (e) {
        print('Ошибка при получении истории упражнений: $e');
      return [];
      }
    }

  // ПОЛУЧИТЬ ПОСЛЕДНИЙ РЕЗУЛЬТАТ ДЛЯ УПРАЖНЕНИЯ
  static Future<Exercise?> getLastExerciseResult(String exerciseName) async {
    final results = await getLastExerciseResults(exerciseName, 1);
    return results.isNotEmpty ? results.first : null;
  }

  // ПОЛУЧИТЬ СРЕДНИЕ ПОКАЗАТЕЛИ ЗА ПОСЛЕДНИЕ N ТРЕНИРОВОК
  static Future<Map<String, dynamic>> getAverageExerciseStats(
      String exerciseName,
      int lastWorkouts,
      ) async {
        final results = await getLastExerciseResults(exerciseName, lastWorkouts);

        if (results.isEmpty) {
          return {
            'weight': 0.0,
            'sets': 0,
            'reps': 0,
            'count': 0,
          };
        }
        double totalWeight = 0;
        int totalSets = 0;
        int totalReps = 0;

        for (var exercise in results) {
          totalWeight += exercise.weight;
          totalSets += exercise.sets;
          totalReps += exercise.reps;
        }

        return{
          'weight': totalWeight / results.length,
          'sets': totalSets ~/ results.length,
          'reps': totalReps ~/ results.length,
          'count': results.length,
        };
  }

  // ПОЛУЧИТЬ ПРОГРЕСС ПО ВЕСУ
  static Future<double> getWeightProgress(String exerciseName) async {
    final lastResults = await getLastExerciseResults(exerciseName, 2);

    if (lastResults.length < 2) {
      return 0.0;
    }

    final currentWeight = lastResults[0].weight;
    final previousWeight = lastResults[1].weight;

    if (previousWeight == 0) return 100.0;

    final progress = ((currentWeight - previousWeight)/previousWeight)*100;
    return double.parse(progress.toStringAsFixed(1));
  }

  // ПОЛУЧИТЬ ПРОГРЕСС ПО ПОВТОРЕНИЯМ
  static Future<double> getRepsProgress(String exerciseName) async {
    final lastResults = await getLastExerciseResults(exerciseName, 2);

    if (lastResults.length < 2) {
      return 0.0;
    }

    final currentReps = lastResults[0].reps;
    final previousReps = lastResults[1].reps;

    if (previousReps == 0) return 100.0;

    final progress = ((currentReps - previousReps)/previousReps)*100;
    return double.parse(progress.toStringAsFixed(1));
  }
}