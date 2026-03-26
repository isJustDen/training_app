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

  List<Map<String, dynamic>> completedSets;

  List <MuscleGroup> muscleGroups;

  bool isTimeBased; // true = на время, false = на повторения (по умолчанию)
  int targetSeconds;

  // КОНСТРУКТОР
  Exercise({
    required this.id,
    required this.name,
    this.weight = 0.0,
    this.sets = 3,
    this.reps = 8,
    this.restTime = 60,
    this.isInCircle = false,
    this.circleNumber = 0,
    this.circleOrder = 0,
    List<Map<String, dynamic>>? completedSets,
    this.muscleGroups = const[],
    this.isTimeBased = false,
    this.targetSeconds = 30,
  }) : completedSets = completedSets ?? [];

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
    List<Map<String, dynamic>>? completedSets,
    List<MuscleGroup> ? muscleGroups,
    bool? isTimeBased,
    int? targetSeconds,
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
      completedSets: completedSets ?? this.completedSets,
      muscleGroups: muscleGroups ?? this.muscleGroups,
      isTimeBased: isTimeBased ?? this.isTimeBased,
      targetSeconds: targetSeconds ?? this.targetSeconds,
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
      'completedSets': completedSets,
      'muscleGroups': muscleGroups.map((g) => g.name).toList(),
      'isTimeBased': isTimeBased,
      'targetSeconds': targetSeconds,
      };
    }

// ФАБРИЧНЫЙ КОНСТРУКТОР ДЛЯ СОЗДАНИЯ ИЗ MAP
// factory - специальный конструктор, может возвращать кэшированные экземпляры
  factory Exercise.fromMap(Map<String, dynamic> map){
    // ОБРАТНАЯ СОВМЕСТИМОСТЬ — если поля нет в старых данных, берём пустой список
    List<MuscleGroup> groups = [];
    if (map['muscleGroups'] != null) {
      for (final name in (map['muscleGroups'] as List)) {
        try {
          // byName кидает исключение если такого значения нет — ловим его
          groups.add(MuscleGroup.values.byName(name.toString()));
        } catch (e){
          print('ОШИБКА: === fromMap: ${map}');
        }
      }
    }

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
      completedSets: List<Map<String, dynamic>>.from(
          (map['completedSets']as List?)?.map((s)=> Map<String,dynamic>.from(s)) ?? [],
      ),
      muscleGroups: groups,
      isTimeBased: map['isTimeBased'] ?? false,
      targetSeconds: map['targetSeconds'] ?? 30,
    );
  }

  // НОВЫЙ МЕТОД: ПРИНАДЛЕЖИТ ЛИ УПРАЖНЕНИЕ КАКОМУ-ЛИБО КРУГУ
  bool get isInAnyCircle => circleNumber > 0;

  // НОВЫЙ МЕТОД: ПОЛУЧИТЬ ИНФОРМАЦИЮ О КРУГЕ В ВИДЕ СТРОКИ
  String get circleInfo => isInAnyCircle ? 'Не в круге':'Круг $circleNumber ($circleOrder)';

  // ПЕРЕОПРЕДЕЛЕНИЕ toString() ДЛЯ ОТЛАДКИ
  @override
  String toString() => 'Exercise(id: $id, name: $name, muscles: ${muscleGroups.map((g) => g.name).join(', ')}';
}

// ГРУППЫ МЫШЦ — перечисление всех возможных категорий
enum MuscleGroup{
  chest,
  back,
  biceps,
  triceps,
  frontDelt,
  midDelt,
  rearDelt,
  abs,
  lowerBack,
  quadriceps,
  hamstrings,
  calves,
  neck,
  forearm,
  glutes,
  other,
}

//ВПОМОГАТЕЛЬНЫЙ КЛАСС. ЧИТАЕМЫЕ НАЗВАНИЯ И ИКОНКИ
class MuscleGroupInfo{
  // Отображаемое название на русском
  static String getName(MuscleGroup group) {
    const names = {
      MuscleGroup.chest:         'Грудь' ,
      MuscleGroup.back:          'Спина',
      MuscleGroup.biceps:        'Бицепс',
      MuscleGroup.triceps:       'Трицепс',
      MuscleGroup.frontDelt:     'Дельты(передние)',
      MuscleGroup.midDelt:       'Дельты(средние)',
      MuscleGroup.rearDelt:      'Дельты (задние)',
      MuscleGroup.abs:           'Пресс',
      MuscleGroup.lowerBack:     'Поясница',
      MuscleGroup.quadriceps:    'Квадрицепсы',
      MuscleGroup.hamstrings:    'Бёдра(задние)',
      MuscleGroup.calves:        'Икры',
      MuscleGroup.neck:          'Шея' ,
      MuscleGroup.forearm:       'Предплечье',
      MuscleGroup.glutes:        'Ягодицы',
      MuscleGroup.other:         'Свои упражнения',
    };
    return names[group] ?? group.name;
  }

  // Иконка для каждой группы мышц
  static String getEmoji(MuscleGroup group) {
    const emojis = {
      MuscleGroup.chest:      '🫁',
      MuscleGroup.back:       '🔙',
      MuscleGroup.biceps:     '💪',
      MuscleGroup.triceps:    '💪',
      MuscleGroup.frontDelt:  '🏋️',
      MuscleGroup.midDelt:    '🏋️',
      MuscleGroup.rearDelt:   '🏋️',
      MuscleGroup.abs:        '⚡',
      MuscleGroup.lowerBack:  '🔩',
      MuscleGroup.quadriceps: '🦵',
      MuscleGroup.hamstrings: '🦵',
      MuscleGroup.calves:     '🦶',
      MuscleGroup.neck:       '🧠',
      MuscleGroup.forearm:    '🤜',
      MuscleGroup.glutes:     '🍑',
      MuscleGroup.other:      '🏃',
    };
    return emojis[group] ?? '💪';
  }
}