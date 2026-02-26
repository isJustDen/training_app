//services/stats_service.dart


import '../models/workout_history.dart';
import '../models/exercise.dart';

// СЕРВИС ДЛЯ РАСЧЕТА СТАТИСТИКИ И ЭФФЕКТИВНОСТИ
class StatsService {
  // РАСЧЕТ ЭФФЕКТИВНОСТИ ДЛЯ ОДНОГО УПРАЖНЕНИЯ
    static double calculateEfficiency({
      required List<WorkoutHistory> history,
      required String exerciseName,
      required int currentReps,
      required int currentSets,
      required double currentWeight,
  }) {
      print('Анализ эффективности для: $exerciseName');
      print('Текущие значения: $currentSets подходов, $currentReps повторений, $currentWeight кг');

      // РАССЧИТЫВАЕМ ТЕКУЩИЙ ОБЪЁМ
      double currentVolume = currentWeight * currentSets * currentReps;
      print('Текущий объём: $currentVolume кг (вес*подходы*повторения)');

    // 1. СОБИРАЕМ ВСЕ ИСТОРИЧЕСКИЕ ДАННЫЕ ПО ЭТОМУ УПРАЖНЕНИЮ
    List<double> historicalVolumes = [];

    for  (var workout in history) {
      for (var exercise in workout.exercises){
        if (exercise.name == exerciseName && exercise.sets > 0 && exercise.reps > 0) {
          double volume = exercise.weight * exercise.sets * exercise.reps;
          historicalVolumes.add(volume);
          print('   Найдено:${exercise.sets} * ${exercise.reps} * ${exercise.weight} кг =  ${volume.toStringAsFixed(1)} кг');
        }
      }
    }

    print('    Исторические объёмы: $historicalVolumes');

    //Если текущие повторения 0 - сразу возвращаем 0% эффективности
    if (currentReps == 0){
      print('Текущие повторения = 0. Возвращаем 0%');
      return 0.0;
    }


    // 2. ЕСЛИ ИСТОРИЧЕСКИХ ДАННЫХ НЕТ - ВОЗВРАЩАЕМ 100%
    if (historicalVolumes.isEmpty){
      print('Нет истоических данных. Возвращаем 100%');
      return 100.0;
    }

    // ФИЛЬТРУЕМ нулевые значения для расчета среднего (но храним их в истории)
    List<double>nonZeroHistoricalVolumes = historicalVolumes.where((volume) => volume>0).toList();

    if(nonZeroHistoricalVolumes.isEmpty){
      print('Все исторические значения = 0. Текущие >0. Возвращаем 200 процентво как бонус');
      return 200.0;
    }

    // 3. РАССЧИТЫВАЕМ СРЕДНЕЕ КОЛИЧЕСТВО ПОВТОРЕНИЙ только по ненулевым значениям
    double averageVolume = nonZeroHistoricalVolumes.reduce((a,b) => a+b)/nonZeroHistoricalVolumes.length;
    print('Средние повторения (без нулей): ${averageVolume.toStringAsFixed(1)}');

    // 4. РАССЧИТЫВАЕМ ЭФФЕКТИВНОСТЬ
    double efficiency = (currentVolume/averageVolume) * 100;
    print('Эффективность:${efficiency.toStringAsFixed(1)} ');

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

  // Получаем реальные значения из последней тренировки

  for (var templateExercise in currentExercises) {
    final exerciseName = templateExercise.name;

    Exercise? lastRealResult = _getLastResultExercise(history, exerciseName);

    final realExercise = lastRealResult ?? templateExercise;

    stats[exerciseName] = ExerciseStats(
      efficiency: calculateEfficiency(
          history: history,
          exerciseName: exerciseName,
          currentReps: realExercise.reps, // Используем реальные повторения
          currentSets: realExercise.sets,
          currentWeight: realExercise.weight,
      ),
      averageWeight: getAverangeWeight(
          history: history,
          exerciseName: exerciseName,
      ),
      progress: calculateProgress(
          history: history,
          exerciseName: exerciseName,
          currentValue: realExercise.reps,
          valueType: ValueType.reps,
      ),
      volumeProgress: calculateVolumeProgress(
          history: history,
          exerciseName: exerciseName,
          currentReps: realExercise.reps,
          currentSets: realExercise.sets,
          currentWeight: realExercise.weight),
    );
  }

  return stats;
  }

  // ИЩЕТ ПОСЛЕДНИЕ РЕЗУЛЬТАТЫ КОНКРЕТНОГО УПРАЖНЕНИЯ
  static Exercise? _getLastResultExercise(
      List<WorkoutHistory> history,
      String exerciseName,){
    // Сортируем от новых к старым
    final sorted = List<WorkoutHistory>.from(history)
        ..sort((a, b) => b.date.compareTo(a.date));

    for (var workout in sorted){
      for (var exercise in workout.exercises){
        if (exercise.name == exerciseName && exercise.sets > 0) {
          return exercise;
        }
      }
    }
    return null;
  }


  //МЕТОДЫ РАСЧЁТА УРОВНЯ ПРОГРЕССА
  static double calculateVolumeProgress({
    required List<WorkoutHistory> history,
    required String exerciseName,
    required int currentReps,
    required int currentSets,
    required double currentWeight,
  }){
      if (history.length < 2) return 0.0;

    // СОРТИРУЕМ ИСТОРИЮ ПО ДАТЕ
    final sortedHistory = List<WorkoutHistory>.from(history)
      ..sort((a,b) => a.date.compareTo(b.date));

    // ИЩЕМ ПОСЛЕДНИЕ 2 ЗНАЧЕНИЯ ОБЪЁМА
    List<double> lastVolumes = [];

    for (var workout in sortedHistory.reversed){
      for (var exercise in workout.exercises){
        if (exercise.name == exerciseName && exercise.sets > 0 && exercise.reps > 0) {
          double volume = exercise.weight * exercise.sets * exercise.reps;
          lastVolumes.add(volume);
          if (lastVolumes.length >= 2) break;
        }
      }
      if (lastVolumes.length >= 2) break;
    }

    if (lastVolumes.length < 2) return 0.0;

    // ТЕКУЩИЙ ОБЪЁМ
    double  currentVolume = currentWeight * currentSets * currentReps;

    // ПРЕДЫДУЩИЙ ОБЪЁМ
    double previousVolume = lastVolumes[1];

    // РАССЧИТЫВАЕМ ПРОГРЕСС
    double progress = ((currentVolume - previousVolume) / previousVolume) * 100;

    return double.parse(progress.toStringAsFixed(1));
  }
}

// ВСПОМОГАТЕЛЬНЫЙ КЛАСС ДЛЯ СТАТИСТИКИ УПРАЖНЕНИЯ
class ExerciseStats{
  double efficiency;
  double averageWeight;
  double progress;
  double volumeProgress;

  ExerciseStats ({
    required this.efficiency,
    required this.progress,
    required this.averageWeight,
    this.volumeProgress = 0.0,
  });
}

// ТИП ЗНАЧЕНИЯ ДЛЯ РАСЧЕТА ПРОГРЕССА
enum ValueType{
  reps,
  weight,
}