//models/workout_circle.dart

import 'exercise.dart';

// МОДЕЛЬ ДЛЯ ПРЕДСТАВЛЕНИЯ КРУГА (СУПЕРСЕТА)
class WorkoutCircle{
  int number;
  String name;
  List<Exercise> exercises;
  int restTime;
  int completedCircles;

  // КОНСТРУКТОР
  WorkoutCircle({
    required this.number,
    this.name = '',
    required this.exercises,
    this.restTime = 90,
    this.completedCircles = 0,
  });

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  WorkoutCircle copyWith({
    int? number,
    String? name,
    List<Exercise>? exercises,
    int? restTime,
    int? completedCircles,
  }) {
    return WorkoutCircle(
        number: number ?? this.number,
        exercises: exercises ?? this.exercises,
        name: name ?? this.name,
        restTime: restTime ?? this.restTime,
        completedCircles: completedCircles ?? this.completedCircles,
    );
  }

  // ДОБАВИТЬ УПРАЖНЕНИЕ В КРУГ
  void addExercises(Exercise exercise) {
    // Устанавливаем упражнению принадлежность к кругу
    final updatedExercise = exercise.copyWith(
      isInCircle: true,
      circleNumber: number,
      circleOrder: exercises.length+1
    );
    exercises.add(updatedExercise);
  }

  // УДАЛИТЬ УПРАЖНЕНИЕ ИЗ КРУГА
  void removeExercise(String exerciseId) {
    exercises.removeWhere((exercise) => exercise.id == exerciseId);

    // Обновляем порядок оставшихся упражнений
    for (int i = 0; i < exercises.length; i++){
      exercises[i] = exercises[i].copyWith(circleOrder: i + 1);
    }
  }

  // ПЕРЕМЕСТИТЬ УПРАЖНЕНИЕ В КРУГЕ
  void reorderExercise(int oldIndex, int newIndex) {
    if (oldIndex < newIndex){
      newIndex -=1;
    }
    final Exercise item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);

    // Обновляем порядок всех упражнений
    for (int i = 0; i < exercises.length; i++){
      exercises[i] = exercises[i].copyWith(circleOrder: i + 1);
    }
  }

  // РАССЧИТАТЬ ОБЩЕЕ ВРЕМЯ ВЫПОЛНЕНИЯ КРУГА (оценочно)
  int get estimatedTime {
    // Предполагаем 30 секунд на подход + время отдыха между подходами
    int totalTime = 0;
    for (var exercise in exercises){
      totalTime += exercise.sets * (30 + exercise.restTime);
    }
    return totalTime;
  }

  // ВСЕ ЛИ УПРАЖНЕНИЯ В КРУГЕ ВЫПОЛНЕНЫ?
  bool get isCompleted {
    // Здесь будет логика проверки после добавления трекинга прогресса
    return false;
  }

  // ПРОГРЕСС В ПРОЦЕНТАХ (0-100)
  double get progressPercentage {
    if (exercises.isEmpty) return 0;
    // Здесь будет расчет прогресса

    return 0;
  }

  @override
  String toString(){
    return 'WorkoutCircle(#$number: ${exercises.length} упражнений, отдых: $restTime с)';
  }




}