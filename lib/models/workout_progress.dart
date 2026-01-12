//models/workout_progress.dart

import 'exercise.dart';

// КЛАСС ДЛЯ ОТСЛЕЖИВАНИЯ ПРОГРЕССА ВЫПОЛНЕНИЯ УПРАЖНЕНИЯ
// Трекер прогресса для одного упражнения во время тренировки

class ExerciseProgress{
  final Exercise exercise; // Исходное упражнение
  int completedSets; // Выполненные подходы
  int completedReps; // Выполненные повторения (в текущем подходе)
  double currentWeight; // Текущий вес (может меняться)

  ExerciseProgress({
    required this.exercise,
    this.completedSets = 0,
    this.completedReps = 0,
    required this.currentWeight,
  });

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  ExerciseProgress copyWith({
    int? completedSets,
    int? completedReps,
    double? currentWeight,
  }) {
    return ExerciseProgress(
        exercise: exercise,
        completedSets: completedSets ?? this.completedSets,
        completedReps: completedReps ?? this.completedReps,
      currentWeight: currentWeight ?? this.currentWeight,
    );
  }

  // ПРОВЕРКА: ВСЕ ЛИ ПОДХОДЫ ВЫПОЛНЕНЫ
  bool get isCompleted{
    return completedSets >= exercise.sets;
  }

  // ПРОГРЕСС В ПРОЦЕНТАХ (0-100)
  double get progressPercentage{
    if (exercise.sets == 0) return 0;
    return (completedSets/exercise.sets) * 100;
  }

  // ОСТАЛОСЬ ПОДХОДОВ
  int get remainingSets{
    return exercise.sets - completedSets;
  }

  // СБРОС ПОВТОРЕНИЙ ДЛЯ НОВОГО ПОДХОДА
  void resetForNextSet(){
    completedReps = 0;
  }
}