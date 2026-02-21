//models/exercise.dart

class Exercise {
  // ПОЛЯ КЛАССА (properties)
  String id;
  String name;
  double weight;
  int sets;
  int reps;
  int restTime;

  // НОВЫЕ ПОЛЯ ДЛЯ ГРУППИРОВКИ В КРУГИ:
  bool isInCircle; // Принадлежит ли упражнение кругу
  int circleNumber; // Номер круга (0 = не в круге, 1+ = номер круга)
  int circleOrder;  // Порядок в круге (1, 2, 3...)

  // КОНСТРУКТОР
  Exercise({
    required this.id,
    required this.name,
    this.weight = 0.0,
    this.sets = 3,
    this.reps = 8,
    this.restTime = 60,
    // НОВЫЕ ПАРАМЕТРЫ С ЗНАЧЕНИЯМИ ПО УМОЛЧАНИЮ:
    this.isInCircle = false,
    this.circleNumber = 0,
    this.circleOrder = 0,
  });

// МЕТОД ДЛЯ КОПИРОВАНИЯ С ИЗМЕНЕНИЯМИ
  Exercise copyWith({
    String? id,
    String? name,
    double? weight,
    int? sets,
    int? reps,
    int? restTime,
    bool? isInCircle,
    int? circleNumber,
    int? circleOrder,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      weight: weight ?? this.weight,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
      isInCircle: isInCircle ?? this.isInCircle,
      circleNumber: circleNumber ?? this.circleNumber,
      circleOrder: circleOrder ?? this.circleOrder,
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
      'isInCircle': isInCircle,
      'circleOrder':circleOrder,
      'circleNumber':circleNumber,
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
      isInCircle: map['isInCircle']??false,
      circleOrder: map['circleOrder']??0,
      circleNumber: map['circleNumber']??0,
    );
  }

  // НОВЫЙ МЕТОД: ПРИНАДЛЕЖИТ ЛИ УПРАЖНЕНИЕ КАКОМУ-ЛИБО КРУГУ
  bool get isInAnyCircle => circleNumber > 0;

  // НОВЫЙ МЕТОД: ПОЛУЧИТЬ ИНФОРМАЦИЮ О КРУГЕ В ВИДЕ СТРОКИ
  String get circleInfo {
    if (isInAnyCircle) return 'Не в круге';
    return 'Круг $circleNumber ($circleOrder)';
  }

  // ПЕРЕОПРЕДЕЛЕНИЕ toString() ДЛЯ ОТЛАДКИ
  @override
  String toString(){
    return 'Exercise(id: $id, name: $name, '
        'weight $weight, sets: $sets, reps: '
        '$reps, circle:${circleNumber>0? "Круг $circleNumber" : "Нет"})';
  }
}