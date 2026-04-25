//services/workout_presets.dart

import '../models/workout_template.dart';
import '../models/workout_category.dart';
import '../models/exercise.dart';

class WorkoutPresets {
  WorkoutPresets._();

  // ШАБЛОНЫ ТРЕНИРОВОК
  static List<WorkoutTemplate>getDefaultTemplates(){
    final now = DateTime.now();
    return [
      ..._gymTemplates(now),
      ..._streetTemplates(now),
    ];
  }

  // ЗАЛ
  static List<WorkoutTemplate> _gymTemplates(DateTime now) => [
    WorkoutTemplate(
      id: 'gym_1',
      name: 'FB. Акцент: грудь',
      dayOfWeek: 'Понедельник',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 'g1_1', name: 'Жим штанги лёжа',        weight: 20,   sets: 3, reps: 8,  restTime: 120),
        Exercise(id: 'g1_2', name: 'Жим тренажёра сидя',     weight: 15,   sets: 3, reps: 10, restTime: 120),
        Exercise(id: 'g1_3', name: 'Тяга блока к поясу',     weight: 40,   sets: 3, reps: 8,  restTime: 120),
        Exercise(id: 'g1_4', name: 'Присед со штангой',      weight: 30,   sets: 3, reps: 8,  restTime: 120),
        Exercise(id: 'g1_5', name: 'Махи гантелей в стороны',weight: 8,    sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g1_6', name: 'Подъём Z-грифа на бицепс',weight: 15, sets: 3, reps: 8,  restTime: 60),
        Exercise(id: 'g1_7', name: 'Подъём ног в висе',      weight: 0,    sets: 3, reps: 10, restTime: 60),
        Exercise(id: 'g1_8', name: 'Разгибание блок (прямая)',weight: 25,  sets: 3, reps: 8,  restTime: 60),
      ],
    ),
    WorkoutTemplate(
      id: 'gym_2',
      name: 'FB. Акцент: спина',
      dayOfWeek: 'Среда',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 'g2_1', name: 'Подтягивания широкие',    weight: 0,  sets: 3, reps: 8,  restTime: 90),
        Exercise(id: 'g2_2', name: 'Тяга штанги к поясу',    weight: 40,  sets: 3, reps: 8,  restTime: 120),
        Exercise(id: 'g2_3', name: 'Отжимания от брусьев',   weight: 0,   sets: 3, reps: 8,  restTime: 90),
        Exercise(id: 'g2_4', name: 'Выпады с гантелями',     weight: 20,  sets: 3, reps: 12, restTime: 90),
        Exercise(id: 'g2_5', name: 'Тяга к подбородку',      weight: 10,  sets: 3, reps: 8,  restTime: 60),
        Exercise(id: 'g2_6', name: 'Подъём гантелей на бицепс',weight: 12,sets: 3, reps: 10, restTime: 60),
        Exercise(id: 'g2_7', name: 'Разгибание блок (верёвка)',weight: 20,sets: 3, reps: 10, restTime: 60),
        Exercise(id: 'g2_8', name: 'Скручивания с паузой',   weight: 0,   sets: 3, reps: 15, restTime: 60),
      ],
    ),
    WorkoutTemplate(
      id: 'gym_3',
      name: 'FB. Акцент: ноги + плечи',
      dayOfWeek: 'Пятница',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 'g3_1', name: 'Становая тяга',           weight: 40, sets: 3, reps: 8,  restTime: 120),
        Exercise(id: 'g3_2', name: 'Жим ногами лёжа',         weight: 60, sets: 3, reps: 10, restTime: 120),
        Exercise(id: 'g3_3', name: 'Армейский жим штанги',    weight: 20, sets: 3, reps: 8,  restTime: 90),
        Exercise(id: 'g3_4', name: 'Разгибание ног в тренажёре',weight: 30,sets: 3,reps: 12,restTime: 60),
        Exercise(id: 'g3_5', name: 'Разводка в наклоне',      weight: 8,  sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g3_6', name: 'Сгибание ног в тренажёре',weight: 25, sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g3_7', name: 'Подъём на носки стоя',    weight: 40, sets: 4, reps: 15, restTime: 45),
        Exercise(id: 'g3_8', name: 'Пресс на турнике',        weight: 0,  sets: 3, reps: 12, restTime: 60),
      ],
    ),
    // СПЛИТ: ГРУДЬ + ТРИЦЕПС
    WorkoutTemplate(
      id: 'gym_4',
      name: 'Сплит: Грудь + Трицепс',
      dayOfWeek: 'Понедельник',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 'g4_1', name: 'Жим штанги лёжа',        weight: 60,  sets: 4, reps: 8,  restTime: 120),
        Exercise(id: 'g4_2', name: 'Жим гантелей лёжа',      weight: 20,  sets: 3, reps: 10, restTime: 90),
        Exercise(id: 'g4_3', name: 'Разводка гантелей лёжа', weight: 12,  sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g4_4', name: 'Кроссовер в тренажёре',  weight: 15,  sets: 3, reps: 15, restTime: 60),
        Exercise(id: 'g4_5', name: 'Французский жим лёжа',   weight: 20,  sets: 3, reps: 10, restTime: 60),
        Exercise(id: 'g4_6', name: 'Разгибание блок (прямая)',weight: 25, sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g4_7', name: 'Отжимания от скамьи',    weight: 0,   sets: 3, reps: 15, restTime: 45),
      ],
    ),
    // СПЛИТ: СПИНА + БИЦЕПС
    WorkoutTemplate(
      id: 'gym_5',
      name: 'Сплит: Спина + Бицепс',
      dayOfWeek: 'Вторник',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 'g5_1', name: 'Подтягивания широкие',    weight: 0,  sets: 4, reps: 8,  restTime: 90),
        Exercise(id: 'g5_2', name: 'Тяга штанги к поясу',    weight: 50,  sets: 4, reps: 8,  restTime: 120),
        Exercise(id: 'g5_3', name: 'Тяга верхнего блока',    weight: 45,  sets: 3, reps: 10, restTime: 90),
        Exercise(id: 'g5_4', name: 'Тяга гантели одной рукой',weight: 20, sets: 3, reps: 10, restTime: 60),
        Exercise(id: 'g5_5', name: 'Гиперэкстензия',         weight: 0,   sets: 3, reps: 15, restTime: 60),
        Exercise(id: 'g5_6', name: 'Подъём штанги на бицепс',weight: 25,  sets: 3, reps: 10, restTime: 60),
        Exercise(id: 'g5_7', name: 'Молотки с гантелями',    weight: 14,  sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g5_8', name: 'Концентрированный подъём',weight: 12, sets: 3, reps: 12, restTime: 45),
      ],
    ),
    // СПЛИТ: НОГИ
    WorkoutTemplate(
      id: 'gym_6',
      name: 'Сплит: Ноги',
      dayOfWeek: 'Четверг',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 'g6_1', name: 'Присед со штангой',              weight: 60,  sets: 4, reps: 8,  restTime: 120),
        Exercise(id: 'g6_2', name: 'Жим ногами лёжа',               weight: 80,  sets: 4, reps: 10, restTime: 90),
        Exercise(id: 'g6_3', name: 'Румынская тяга',                 weight: 50,  sets: 3, reps: 10, restTime: 90),
        Exercise(id: 'g6_4', name: 'Разгибание ног в тренажёре',     weight: 35,  sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g6_5', name: 'Сгибание ног в тренажёре',       weight: 30,  sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g6_6', name: 'Болгарские сплит-приседания',    weight: 15,  sets: 3, reps: 10, restTime: 90),
        Exercise(id: 'g6_7', name: 'Ягодичный мост',                 weight: 60,  sets: 3, reps: 15, restTime: 60),
        Exercise(id: 'g6_8', name: 'Подъём на носки стоя',           weight: 50,  sets: 4, reps: 20, restTime: 45),
      ],
    ),
    // СПЛИТ: ПЛЕЧИ
    WorkoutTemplate(
      id: 'gym_7',
      name: 'Сплит: Плечи',
      dayOfWeek: 'Пятница',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 'g7_1', name: 'Жим гантелей сидя',       weight: 18, sets: 4, reps: 10, restTime: 90),
        Exercise(id: 'g7_2', name: 'Армейский жим штанги',    weight: 30, sets: 3, reps: 8,  restTime: 90),
        Exercise(id: 'g7_3', name: 'Махи гантелей в стороны', weight: 10, sets: 4, reps: 15, restTime: 60),
        Exercise(id: 'g7_4', name: 'Махи гантелей вперёд',    weight: 8,  sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g7_5', name: 'Разводка в наклоне',      weight: 10, sets: 3, reps: 15, restTime: 60),
        Exercise(id: 'g7_6', name: 'Тяга к подбородку',       weight: 20, sets: 3, reps: 12, restTime: 60),
        Exercise(id: 'g7_7', name: 'Шраги со штангой',        weight: 50, sets: 3, reps: 15, restTime: 60),
        Exercise(id: 'g7_8', name: 'Скручивания лёжа',        weight: 0,  sets: 3, reps: 20, restTime: 45),
      ],
    ),
  ];


  // УЛИЦА / КАЛИСТЕНИКА
  static List<WorkoutTemplate> _streetTemplates(DateTime now) => [
    WorkoutTemplate(
      id: 'street_1',
      name: 'Калистеника: верх тела',
      dayOfWeek: 'Понедельник',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 's1_1', name: 'Подтягивания широкие',    weight: 0, sets: 4, reps: 8,  restTime: 90),
        Exercise(id: 's1_2', name: 'Отжимания от пола',       weight: 0, sets: 4, reps: 15, restTime: 60),
        Exercise(id: 's1_3', name: 'Подтягивания узкие',      weight: 0, sets: 3, reps: 8,  restTime: 90),
        Exercise(id: 's1_4', name: 'Отжимания узким хватом',  weight: 0, sets: 3, reps: 12, restTime: 60),
        Exercise(id: 's1_5', name: 'Австралийские подтягивания',weight: 0,sets: 3,reps: 12, restTime: 60),
        Exercise(id: 's1_6', name: 'Отжимания от брусьев',    weight: 0, sets: 3, reps: 10, restTime: 90),
        Exercise(id: 's1_7', name: 'Подъём ног в висе',       weight: 0, sets: 3, reps: 12, restTime: 60),
      ],
    ),
    WorkoutTemplate(
      id: 'street_2',
      name: 'Калистеника: ноги + кор',
      dayOfWeek: 'Среда',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 's2_1', name: 'Приседания',              weight: 0, sets: 4, reps: 20, restTime: 60),
        Exercise(id: 's2_2', name: 'Выпады',                  weight: 0, sets: 3, reps: 15, restTime: 60),
        Exercise(id: 's2_3', name: 'Прыжки на месте',         weight: 0, sets: 3, reps: 20, restTime: 60),
        Exercise(id: 's2_4', name: 'Планка',                  weight: 0, sets: 3, reps: 1,  restTime: 60,
            isTimeBased: true, targetSeconds: 60),
        Exercise(id: 's2_5', name: 'Скручивания лёжа',        weight: 0, sets: 3, reps: 20, restTime: 45),
        Exercise(id: 's2_6', name: 'Подъём ног лёжа',         weight: 0, sets: 3, reps: 15, restTime: 45),
        Exercise(id: 's2_7', name: 'Берпи',                   weight: 0, sets: 3, reps: 10, restTime: 90),
      ],
    ),
    WorkoutTemplate(
      id: 'street_3',
      name: 'Калистеника: фулбоди',
      dayOfWeek: 'Пятница',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 's3_1', name: 'Подтягивания широкие',    weight: 0, sets: 3, reps: 8,  restTime: 90),
        Exercise(id: 's3_2', name: 'Приседания',              weight: 0, sets: 3, reps: 20, restTime: 60),
        Exercise(id: 's3_3', name: 'Отжимания от пола',       weight: 0, sets: 3, reps: 15, restTime: 60),
        Exercise(id: 's3_4', name: 'Выпады',                  weight: 0, sets: 3, reps: 12, restTime: 60),
        Exercise(id: 's3_5', name: 'Отжимания от брусьев',    weight: 0, sets: 3, reps: 10, restTime: 90),
        Exercise(id: 's3_6', name: 'Планка',                  weight: 0, sets: 3, reps: 1,  restTime: 60,
            isTimeBased: true, targetSeconds: 45),
        Exercise(id: 's3_7', name: 'Подъём ног в висе',       weight: 0, sets: 3, reps: 10, restTime: 60),
        Exercise(id: 's3_8', name: 'Берпи',                   weight: 0, sets: 3, reps: 8,  restTime: 90),
      ],
    ),
    WorkoutTemplate(
      id: 'street_4',
      name: 'Турник: интенсив',
      dayOfWeek: 'По будням',
      createdAt: now, updatedAt: now,
      exercises: [
        Exercise(id: 's4_1', name: 'Подтягивания широкие',    weight: 0, sets: 5, reps: 6,  restTime: 120),
        Exercise(id: 's4_2', name: 'Подтягивания узкие',      weight: 0, sets: 4, reps: 8,  restTime: 90),
        Exercise(id: 's4_3', name: 'Австралийские подтягивания',weight:0, sets: 4, reps: 12, restTime: 60),
        Exercise(id: 's4_4', name: 'Подъём ног в висе',       weight: 0, sets: 4, reps: 10, restTime: 60),
        Exercise(id: 's4_5', name: 'Вис на перекладине',      weight: 0, sets: 3, reps: 1,  restTime: 60,
            isTimeBased: true, targetSeconds: 30),
        Exercise(id: 's4_6', name: 'Отжимания от пола',       weight: 0, sets: 4, reps: 20, restTime: 60),
      ],
    ),
  ];

  // КАТЕГОРИИ
  static List<WorkoutCategory> getDefaultCategories() {
    final now = DateTime.now();
    return [
      WorkoutCategory(
        id: 'cat_gym',
        name: 'Зал',
        emoji: '🏋️',
        color: '#FF2979FF',
        createdAt: now,
        groups: [
          WorkoutGroup(
            id: 'group_gym_fb',
            name: 'Фулбоди',
            templateIds: ['gym_1', 'gym_2', 'gym_3'],
          ),
          WorkoutGroup(
            id: 'group_gym_split',
            name: 'Сплит',
            templateIds: ['gym_4', 'gym_5', 'gym_6', 'gym_7'],
          ),
        ],
      ),
      WorkoutCategory(
        id: 'cat_street',
        name: 'Улица',
        emoji: '🌳',
        color: '#FF4CAF50',
        createdAt: now,
        groups: [
          WorkoutGroup(
            id: 'group_street_main',
            name: 'Калистеника',
            templateIds: ['street_1', 'street_2', 'street_3'],
          ),
          WorkoutGroup(
            id: 'group_street_bar',
            name: 'Турник',
            templateIds: ['street_4'],
          ),
        ],
      ),
    ];
  }
}