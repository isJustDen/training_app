//models/exercise.dart

class Exercise {
  // ПОЛЯ КЛАССА (properties)
  String id;
  String name;
  double weight;
  int sets;
  int reps;
  int restTime;

  // КОНСТРУКТОР
  // Полезно для обновления объектов
  Exercise({
    required this.id,
    required this.name,
    this.weight = 0.0,
    this.sets = 3,
    this.reps = 8,
    this.restTime = 60,
  });

// МЕТОД ДЛЯ КОПИРОВАНИЯ С ИЗМЕНЕНИЯМИ
  Exercise copyWith({
    String? id,
    String? name,
    double? weight,
    int? sets,
    int? reps,
    int? restTime,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
    );
  }

// МЕТОД ДЛЯ ПРЕОБРАЗОВАНИЯ В MAP (для сохранения)
  // Map - ассоциативный массив
  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      };
    }

// ФАБРИЧНЫЙ КОНСТРУКТОР ДЛЯ СОЗДАНИЯ ИЗ MAP
// factory - специальный конструктор, может возвращать кэшированные экземпляры
  factory Exercise.fromMap(Map<String, dynamic> map){
    return Exercise(
      id: map['id'],
      name: map['name'],
      weight: map['weight']?.toDouble() ?? 0.0,
      sets: map['sets'] ?? 3,
      reps: map['reps']?? 8,
      restTime: map['restTime'] ?? 60,
    );
  }
// ПЕРЕОПРЕДЕЛЕНИЕ toString() ДЛЯ ОТЛАДКИ
  @override
  String toString(){
    return 'Exercise(id: $id, name: $name, weight $weight, sets: $sets, reps: $reps)';
  }
}