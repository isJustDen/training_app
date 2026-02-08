//models/workout_progress.dart

import 'set_result.dart';

import 'exercise.dart';

// КЛАСС ДЛЯ ОТСЛЕЖИВАНИЯ ПРОГРЕССА ВЫПОЛНЕНИЯ УПРАЖНЕНИЯ
// Трекер прогресса для одного упражнения во время тренировки

class ExerciseProgress{
  final Exercise exercise; // Исходное упражнение
  List<SetResult> completedSets=[];
  int currentReps = 0;
  double currentWeight;

  ExerciseProgress({
    required this.exercise,
    required this.currentWeight,
    this.currentReps = 0,
    List<SetResult>? completedSets,
  }): completedSets = completedSets ?? [];

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  ExerciseProgress copyWith({
    List<SetResult>? completedSets,
    int? currentReps,
    double? currentWeight,
    Exercise? exercise,
  }) {
    return ExerciseProgress(
      exercise: exercise ?? this.exercise,
      completedSets: completedSets ?? this.completedSets,
      currentReps: currentReps ?? this.currentReps,
      currentWeight: currentWeight ?? this.currentWeight,
    );
  }

  // ПРОВЕРКА: ВСЕ ЛИ ПОДХОДЫ ВЫПОЛНЕНЫ
  bool get isCompleted{
    return completedSets.length >= exercise.sets;
  }

  // ПРОГРЕСС В ПРОЦЕНТАХ (0-100)
  double get progressPercentage{
    if (exercise.sets == 0) return 0;
    return (completedSets.length / exercise.sets) * 100;
  }

  // ОСТАЛОСЬ ПОДХОДОВ
  int get remainingSets{
    return exercise.sets - completedSets.length;
  }

  // Добавить выполненный подход
  void addCompletedSet(int reps, double weight) {
    completedSets.add(SetResult(
      setNumber: completedSets.length + 1,
      completedReps: reps,
      weight: weight,
    ));
    currentReps = 0;
  }

  // Получить общее количество повторений
  int get totalReps{
    return completedSets.fold(0, (sum, set) => sum + set.completedReps);
  }

  // Получить количество выполненных подходов (удобный геттер)
  int get completedSetsCount{
    return completedSets.length;
  }
}