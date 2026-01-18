//services/stats_service.dart


import '../models/workout_history.dart';
import '../models/exercise.dart';

// СЕРВИС ДЛЯ РАСЧЕТА СТАТИСТИКИ И ЭФФЕКТИВНОСТИ
class StatsService {
  // РАСЧЕТ ЭФФЕКТИВНОСТИ ДЛЯ ОДНОГО УПРАЖНЕНИЯ
  // Формула: (текущие повторения / средние повторения) × 100%
  static double calculateEfficiency({
    required List<WorkoutHistory> history,
    required String exerciseName,
    required int currentReps,
  }) {
    // 1. СОБИРАЕМ ВСЕ ИСТОРИЧЕСКИЕ ДАННЫЕ ПО ЭТОМУ УПРАЖНЕНИЮ
    List<int> historicalReps = [];

    for  (var workout in history) {
      for (var exercise in workout.exercises){
        if (exercise.name == exerciseName && exercise.reps > 0){
          historicalReps.add(exercise.reps);
        }
      }
    }

    // 2. ЕСЛИ ИСТОРИЧЕСКИХ ДАННЫХ НЕТ - ВОЗВРАЩАЕМ 100%
    if (historicalReps.isEmpty){
      return 100.0;
    }


    // 3. РАССЧИТЫВАЕМ СРЕДНЕЕ КОЛИЧЕСТВО ПОВТОРЕНИЙ
    double averageReps = historicalReps.reduce((a,b) => a+b)/historicalReps.length;

    // 4. РАССЧИТЫВАЕМ ЭФФЕКТИВНОСТЬ
    double efficiency = (currentReps/averageReps) * 100;

    // 5. ОКРУГЛЯЕМ ДО 1 ЗНАКА ПОСЛЕ ЗАПЯТОЙ
    return double.parse(efficiency.toStringAsFixed(1));
  }

  // ПОЛУЧИТЬ СРЕДНИЙ ВЕС ДЛЯ УПРАЖНЕНИЯ
  static double getAverangeWeight({
    required List<WorkoutHistory> history,
    required String exerciseName,
  }) {
    List<double> weights = [];

    for (var workout in history) {
      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName && exercise.weight >0){
          weights.add(exercise.weight);
        }
      }
    }

    if (weights.isEmpty) return 0.0;

    double sum =weights.reduce((a, b) => a + b);
    return double.parse((sum/weights.length).toStringAsFixed(1));
  }

  // ПОЛУЧИТЬ ИСТОРИЮ ПРОГРЕССА ПО УПРАЖНЕНИЮ
  static Map<DateTime, int> getProgressHistory({
    required List<WorkoutHistory> history,
    required String exerciseName,
  }) {
    Map<DateTime, int> progress = {};

    for (var workout in history){
      for (var exercise in workout.exercises){
        if (exercise.name == exerciseName){
          // Используем только дату (без времени) для группировки
          DateTime date = DateTime(
            workout.date.year,
            workout.date.month,
            workout.date.day,
          );
          progress[date] = exercise.reps;
        }
      }
    }

    // СОРТИРУЕМ ПО ДАТЕ
    final sortedEntries = progress.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  // РАСЧЕТ ТЕКУЩЕГО ПРОГРЕССА (рост/падение в %)
  static double calculateProgress({
    required List<WorkoutHistory> history,
    required String exerciseName,
    required int currentValue,
    required ValueType valueType,
  }) {
    if (history.length < 2) return 0.0;

    // ПОЛУЧАЕМ ПОСЛЕДНИЕ 2 ЗНАЧЕНИЯ
    List<double> lastValues = [];

    // СОРТИРУЕМ ИСТОРИЮ ПО ДАТЕ (от старых к новым)
    final sortedHistory = List<WorkoutHistory>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    // ИЩЕМ ЗНАЧЕНИЯ ДЛЯ ЭТОГО УПРАЖНЕНИЯ
    for (var workout in sortedHistory.reversed){
      for (var exercise in workout.exercises) {
        if (exercise.name == exerciseName) {
          double value = valueType == ValueType.reps
              ? exercise.reps.toDouble()
              : exercise.weight;

          if (value > 0){
            lastValues.add(value);
            if (lastValues.length >= 2) break;
          }
        }
      }
      if (lastValues.length >= 2) break;
    }
    if (lastValues.length < 2) return 0.0;

    // РАССЧИТЫВАЕМ ПРОГРЕСС
    double previousValue = lastValues[1];
    double progress = ((currentValue - previousValue)/previousValue) * 100;

    return double.parse(progress.toStringAsFixed(1));
  }

  // ПОЛУЧИТЬ СТАТИСТИКУ ПО ВСЕМ УПРАЖНЕНИЯМ
  static Map<String, ExerciseStats> getAllExercisesStats({
    required List<WorkoutHistory> history,
    required List <Exercise> currentExercises,
  }) {
  Map<String, ExerciseStats> stats = {};

  for (var exercise in currentExercises) {
    stats[exercise.name] = ExerciseStats(
      efficiency: calculateEfficiency(
          history: history,
          exerciseName: exercise.name,
          currentReps: exercise.reps,
      ),
      averageWeight: getAverangeWeight(
          history: history,
          exerciseName: exercise.name,
      ),
      progress: calculateProgress(
          history: history,
          exerciseName: exercise.name,
          currentValue: exercise.reps,
          valueType: ValueType.reps,
      ),
    );
  }

  return stats;
  }
}

// ВСПОМОГАТЕЛЬНЫЙ КЛАСС ДЛЯ СТАТИСТИКИ УПРАЖНЕНИЯ
class ExerciseStats{
  double efficiency;
  double averageWeight;
  double progress;

  ExerciseStats ({
    required this.efficiency,
    required this.progress,
    required this.averageWeight,
  });
}

// ТИП ЗНАЧЕНИЯ ДЛЯ РАСЧЕТА ПРОГРЕССА
enum ValueType{
  reps,
  weight,
}