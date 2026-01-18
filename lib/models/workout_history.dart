//models/workout_history.dart

import 'exercise.dart';

// МОДЕЛЬ ДЛЯ СОХРАНЕНИЯ РЕЗУЛЬТАТА ОДНОЙ ТРЕНИРОВКИ
// Хранит фактические выполненные данные
class WorkoutHistory{
  String id;
  String templateId;
  DateTime date;
  List<Exercise> exercises;
  int duration;
  String? notes;

  WorkoutHistory({
    required this.id,
    required this.templateId,
    required this.date,
    required this.exercises,
    this.duration = 0,
    this.notes,
  });

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  WorkoutHistory copyWith({
    String? id,
    String? templateId,
    DateTime? date,
    List<Exercise>? exercises,
    int? duration,
    String? notes,
}){
    return WorkoutHistory(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        date: date ?? this.date,
        exercises: exercises ?? this.exercises,
        duration: duration ?? this.duration,
        notes: notes ?? this.notes,
    );
  }

  // ПРЕОБРАЗОВАНИЕ В MAP (для сохранения)
  Map<String, dynamic> toMap() {
    return {
      'id':id,
      'templateId':templateId,
      'date': date.toIso8601String(),
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'duration': duration,
      'notes': notes,
    };
  }

  // СОЗДАНИЕ ИЗ MAP (для загрузки)
  factory WorkoutHistory.fromMap(Map<String, dynamic> map){
    return WorkoutHistory(
      id: map['id'],
      templateId: map['templateId'],
      date: DateTime.parse(map['date']),
      exercises: List<Exercise>.from(
          (map['exercises'] as List?)?.map((x) => Exercise.fromMap(x)) ?? [],
      ),
      duration: map['duration'] ?? 0,
      notes: map['notes'],
    );
  }

  // ПОЛУЧИТЬ ОБЩИЙ ОБЪЕМ ТРЕНИРОВКИ (вес × подходы × повторения)
  double get totalVolume{
    double volume = 0;
    for (var exercise in exercises){
      volume += exercise.weight * exercise.sets * exercise.reps;
    }
    return volume;
  }

  @override
  String toString() {
    return 'WorkoutHistory (date: ${date}, exercises: ${exercises.length}, volume ${totalVolume.toStringAsFixed(1)} кг';
  }
}