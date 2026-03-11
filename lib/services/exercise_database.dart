// services/exercise_database.dart

import '../models/exercise.dart';

// БАЗА УПРАЖНЕНИЙ — статический справочник всех известных упражнений
class ExerciseDatabase {

  ExerciseDatabase._();   // Приватный конструктор — класс нельзя создать, только использовать статически

  // ВСЕ УПРАЖНЕНИЯ БАЗЫ
  static const List<_ExerciseTemplate> _all = [
    // ───── ГРУДЬ ─────
    _ExerciseTemplate('Жим штанги лёжа',         [MuscleGroup.chest, MuscleGroup.triceps, MuscleGroup.frontDelt]),
    _ExerciseTemplate('Жим гантелей лёжа',        [MuscleGroup.chest, MuscleGroup.triceps]),
    _ExerciseTemplate('Жим в тренажёре сидя',     [MuscleGroup.chest, MuscleGroup.triceps]),
    _ExerciseTemplate('Разводка гантелей лёжа',   [MuscleGroup.chest]),
    _ExerciseTemplate('Отжимания от пола',         [MuscleGroup.chest, MuscleGroup.triceps, MuscleGroup.frontDelt]),
    _ExerciseTemplate('Отжимания от брусьев',      [MuscleGroup.chest, MuscleGroup.triceps]),
    _ExerciseTemplate('Кроссовер в тренажёре',    [MuscleGroup.chest]),
    _ExerciseTemplate('Пуловер с гантелей',        [MuscleGroup.chest, MuscleGroup.back]),

    // ───── СПИНА ─────
    _ExerciseTemplate('Подтягивания широкие',      [MuscleGroup.back, MuscleGroup.biceps]),
    _ExerciseTemplate('Подтягивания узкие',        [MuscleGroup.back, MuscleGroup.biceps]),
    _ExerciseTemplate('Тяга штанги к поясу',       [MuscleGroup.back, MuscleGroup.biceps, MuscleGroup.rearDelt]),
    _ExerciseTemplate('Тяга гантели одной рукой',  [MuscleGroup.back, MuscleGroup.biceps]),
    _ExerciseTemplate('Тяга блока к поясу',        [MuscleGroup.back, MuscleGroup.biceps]),
    _ExerciseTemplate('Тяга верхнего блока',       [MuscleGroup.back, MuscleGroup.biceps]),
    _ExerciseTemplate('Гиперэкстензия',            [MuscleGroup.lowerBack, MuscleGroup.glutes, MuscleGroup.hamstrings]),
    _ExerciseTemplate('Тяга тренажёра к поясу',    [MuscleGroup.back, MuscleGroup.biceps]),
    _ExerciseTemplate('Шраги со штангой',          [MuscleGroup.neck, MuscleGroup.back]),

    // ───── ПЛЕЧИ ─────
    _ExerciseTemplate('Армейский жим штанги',      [MuscleGroup.frontDelt, MuscleGroup.midDelt, MuscleGroup.triceps]),
    _ExerciseTemplate('Жим гантелей сидя',         [MuscleGroup.frontDelt, MuscleGroup.midDelt]),
    _ExerciseTemplate('Махи гантелей в стороны',   [MuscleGroup.midDelt]),
    _ExerciseTemplate('Махи гантелей вперёд',      [MuscleGroup.frontDelt]),
    _ExerciseTemplate('Тяга к подбородку',         [MuscleGroup.midDelt, MuscleGroup.rearDelt]),
    _ExerciseTemplate('Разводка в наклоне',        [MuscleGroup.rearDelt]),
    _ExerciseTemplate('Жим тренажёра (плечи)',     [MuscleGroup.frontDelt, MuscleGroup.midDelt]),

    // ───── БИЦЕПС ─────
    _ExerciseTemplate('Подъём штанги на бицепс',   [MuscleGroup.biceps]),
    _ExerciseTemplate('Подъём Z-грифа на бицепс',  [MuscleGroup.biceps]),
    _ExerciseTemplate('Подъём гантелей на бицепс', [MuscleGroup.biceps]),
    _ExerciseTemplate('Молотки с гантелями',        [MuscleGroup.biceps, MuscleGroup.forearm]),
    _ExerciseTemplate('Бицепс в блоке стоя',       [MuscleGroup.biceps]),
    _ExerciseTemplate('Концентрированный подъём',   [MuscleGroup.biceps]),

    // ───── ТРИЦЕПС ─────
    _ExerciseTemplate('Французский жим лёжа',      [MuscleGroup.triceps]),
    _ExerciseTemplate('Разгибание блок (прямая)',   [MuscleGroup.triceps]),
    _ExerciseTemplate('Разгибание блок (верёвка)',  [MuscleGroup.triceps]),
    _ExerciseTemplate('Жим узким хватом',           [MuscleGroup.triceps, MuscleGroup.chest]),
    _ExerciseTemplate('Разгибание за головой',      [MuscleGroup.triceps]),
    _ExerciseTemplate('Отжимания от скамьи',       [MuscleGroup.triceps, MuscleGroup.chest]),

    // ───── НОГИ — передняя поверхность ─────
    _ExerciseTemplate('Присед со штангой',         [MuscleGroup.quadriceps, MuscleGroup.glutes]),
    _ExerciseTemplate('Жим ногами лёжа',           [MuscleGroup.quadriceps, MuscleGroup.glutes]),
    _ExerciseTemplate('Выпады со штангой',          [MuscleGroup.quadriceps, MuscleGroup.glutes]),
    _ExerciseTemplate('Выпады с гантелями',         [MuscleGroup.quadriceps, MuscleGroup.glutes]),
    _ExerciseTemplate('Разгибание ног в тренажёре', [MuscleGroup.quadriceps]),
    _ExerciseTemplate('Болгарские сплит-приседания',[MuscleGroup.quadriceps, MuscleGroup.glutes]),
    _ExerciseTemplate('Сисси-приседания',           [MuscleGroup.quadriceps]),

    // ───── НОГИ — задняя поверхность ─────
    _ExerciseTemplate('Становая тяга',             [MuscleGroup.hamstrings, MuscleGroup.lowerBack, MuscleGroup.glutes]),
    _ExerciseTemplate('Румынская тяга',            [MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.lowerBack]),
    _ExerciseTemplate('Сгибание ног в тренажёре',  [MuscleGroup.hamstrings]),
    _ExerciseTemplate('Ягодичный мост',            [MuscleGroup.glutes, MuscleGroup.hamstrings]),
    _ExerciseTemplate('Гиперэкстензия с весом',    [MuscleGroup.hamstrings, MuscleGroup.lowerBack]),

    // ───── ИКРЫ ─────
    _ExerciseTemplate('Подъём на носки стоя',      [MuscleGroup.calves]),
    _ExerciseTemplate('Подъём на носки сидя',      [MuscleGroup.calves]),
    _ExerciseTemplate('Икры в тренажёре',          [MuscleGroup.calves]),

    // ───── ПРЕСС ─────
    _ExerciseTemplate('Скручивания лёжа',          [MuscleGroup.abs]),
    _ExerciseTemplate('Скручивания с паузой',      [MuscleGroup.abs]),
    _ExerciseTemplate('Подъём ног в висе',         [MuscleGroup.abs]),
    _ExerciseTemplate('Планка',                    [MuscleGroup.abs, MuscleGroup.lowerBack]),
    _ExerciseTemplate('Велосипед',                 [MuscleGroup.abs]),
    _ExerciseTemplate('Пресс на турнике',          [MuscleGroup.abs]),
    _ExerciseTemplate('Ролик для пресса',          [MuscleGroup.abs, MuscleGroup.lowerBack]),

    // ───── ПРЕДПЛЕЧЬЕ ─────
    _ExerciseTemplate('Сгибание запястий',         [MuscleGroup.forearm]),
    _ExerciseTemplate('Пронация/супинация',        [MuscleGroup.forearm]),
    _ExerciseTemplate('Вис на перекладине',        [MuscleGroup.forearm, MuscleGroup.back]),

    // ───── ШЕЯ ─────
    _ExerciseTemplate('Шраги с гантелями',         [MuscleGroup.neck, MuscleGroup.back]),
    _ExerciseTemplate('Наклоны головы с сопротивлением', [MuscleGroup.neck]),
  ];

  // ПОИСК ПО ЧАСТИЧНОМУ СОВПАДЕНИЮ НАЗВАНИЯ
  static List<_ExerciseTemplate> search (String query) {
    if (query.isEmpty) return [];

    final lower = query.toLowerCase();
    return _all
        .where((e) => e.name.toLowerCase().contains(lower))
        .take(8)
        .toList();
  }

  // ФИЛЬТРАЦИЯ ПО ГРУППАМ МЫШЦ
  // Используется генератором тренировок
  static List<_ExerciseTemplate> getByMyscleGroups(List<MuscleGroup> groups){
    if (groups.isEmpty) return [];

    return _all.where((e) {
      return e.muscleGroups.any((muscle) => groups.contains(muscle));
    }).toList();
  }

  // ПОЛУЧИТЬ ВСЕ УПРАЖНЕНИЯ (для полного списка)
  static List<_ExerciseTemplate> getAll() => List.unmodifiable(_all);
}

// ШАБЛОН УПРАЖНЕНИЯ — только название и мышцы, без параметров тренировки
class _ExerciseTemplate{
final String name;
final List<MuscleGroup> muscleGroups;

const _ExerciseTemplate(this.name, this.muscleGroups);
}


