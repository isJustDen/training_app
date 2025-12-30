//models/workout_template.dart

import 'exercise.dart';

// Шаблон тренировки - коллекция упражнений на определенный день
class WorkoutTemplate {
  // ПОЛЯ КЛАССА (properties)
  String id;
  String name;
  String dayOfWeek;
  List<Exercise> exercises;
  DateTime createdAt;
  DateTime updatedAt;

  // КОНСТРУКТОР
  WorkoutTemplate({
   required this.id,
   required this.name,
   required this.dayOfWeek,
   required this.exercises,
   required this.createdAt,
   required this.updatedAt,
});

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? dayOfWeek,
    List<Exercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
// ПРЕОБРАЗОВАНИЕ В MAP
  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'name': name,
      'dayOfWeek': dayOfWeek,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

// СОЗДАНИЕ ИЗ MAP
  factory WorkoutTemplate.fromMap(Map<String, dynamic>map){
    return WorkoutTemplate(
      id: map['id'],
      name: map['name'],
      dayOfWeek: map['dayOfWeek'],
      // Преобразуем список Map в список Exercise
      exercises: List<Exercise>.from(
        (map['exercises'] as List?)?.map((x) => Exercise.fromMap(x)) ?? [],
      ),
      createdAt: DateTime.parse(map['createdAt']), // Строку в DateTime
      updatedAt: DateTime.parse(map['updatedAt'])
    );
  }

// ПОЛЕЗНЫЕ МЕТОДЫ
// Добавить упражнен
  void addExercise(Exercise exercise){
    exercises.add(exercise);
    updatedAt = DateTime.now();
  }

// Удалить упражнение по индексу
  void removeExercise(int index) {
    if (index >= 0 && index < exercises.length){
      exercises.removeAt(index);
      updatedAt = DateTime.now();
    }
  }

  @override
  String toString() {
    return 'WorkoutTemplate(name :$name, day: $dayOfWeek, exercises: ${exercises
        .length})';
  }
}