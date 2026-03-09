//models/measurement.dart

// МОДЕЛЬ ЗАМЕРА — хранит один "снимок" состояния пользователя
class Measurement {
  final String id;
  final DateTime date; // Дата замера (выбирается пользователем)
  final MeasurementType type; // Тип: силовой или физический
  final Map<String, MeasurementEntry> entries; // Все показатели
  final List<String> photoPaths; // Пути к фото
  final String? notes; // Заметки

  const Measurement({
    required this.id,
    required this.date,
    required this.type,
    required this.entries,
    this.photoPaths = const [],
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'type': type.name,
    'entries': entries.map((k, v) => MapEntry(k, v.toMap())),
    'photoPaths': photoPaths,
    'notes': notes,
  };

  factory Measurement.fromMap(Map<String, dynamic>map) => Measurement(
      id: map['id'],
      date: DateTime.parse(map['date']),
      type: MeasurementType.values.byName(map['type']),
      entries: (map['entries'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, MeasurementEntry.fromMap(v)),
      ),
      photoPaths: List<String>.from(map['photoPaths'] ?? []),
      notes: map['notes'],
  );

  Measurement copyWith({
    DateTime? date,
    Map<String, MeasurementEntry> ? entries,
    List<String>? photoPaths,
    String? notes,
  }) => Measurement(
      id: id,
      date: date ?? this.date,
      type: type,
      entries: entries ?? this.entries,
      photoPaths: photoPaths ?? this.photoPaths,
      notes: notes ?? this.notes,
  );
}

// ТИП ЗАМЕРА
enum MeasurementType{
  strength, // Силовые показатели
  physical, // Физические замеры
}

// ОДНА ЗАПИСЬ ЗАМЕРА
// Используется для обоих типов
class MeasurementEntry{
  final String name; // Название показателя
  final double value; // Основное значение
  final int? reps; // Повторения (только для силовых)
  final String unit; // Единица измерения (кг, см, и т.д.)

  const MeasurementEntry({
    required this.name,
    required this.value,
    this.reps,
    this.unit = '',
  });
  Map<String, dynamic> toMap() => {
    'name': name,
    'value': value,
    'reps': reps,
    'unit': unit,
  };

  factory MeasurementEntry.fromMap(Map<String, dynamic> map) => MeasurementEntry(
      name: map['name'],
      value: (map['value'] as num).toDouble(),
      reps: map['reps'],
    unit:  map['unit'] ?? '',
  );
}

// ШАБЛОНЫ ПОКАЗАТЕЛЕЙ ПО УМОЛЧАНИЮ
class MeasurementDefaults{
  // СИЛОВЫЕ — вес × повторения
  static const List<Map<String, String>> strengthFields = [
  {'key': 'bench_press',   'name': 'Жим лёжа',               'unit': 'кг'},
  {'key': 'squat',         'name': 'Присед',                 'unit': 'кг'},
  {'key': 'bicep_curl',    'name': 'Подъём на бицепс',       'unit': 'кг'},
  {'key': 'weighted_pull', 'name': 'Подтягивания с весом',   'unit': 'кг'},
  ];

  // ФИЗИЧЕСКИЕ — только значение
  static const List<Map<String, String>> physicalFields = [
    {'key': 'weight',         'name': 'Вес тела',               'unit': 'кг'},
    {'key': 'height',         'name': 'Рост',                   'unit': 'см'},
    {'key': 'chest',          'name': 'Объём грудной клетки',   'unit': 'см'},
    {'key': 'waist',          'name': 'Талия',                  'unit': 'см'},
    {'key': 'shoulders',      'name': 'Объём плеч',             'unit': 'см'},
    {'key': 'hips',           'name': 'Бёдра',                  'unit': 'см'},
    {'key': 'bicep_left',     'name': 'Бицепс (левый)',         'unit': 'см'},
    {'key': 'bicep_right',    'name': 'Бицепс (правый)',        'unit': 'см'},
    {'key': 'forearm_left',   'name': 'Предплечье (левое)',     'unit': 'см'},
    {'key': 'forearm_right',  'name': 'Предплечье (правое)',    'unit': 'см'},
    {'key': 'thigh_left',     'name': 'Объём ноги (левое)',     'unit': 'см'},
    {'key': 'thigh_right',    'name': 'Объём ноги (правое)',    'unit': 'см'},
    {'key': 'calf_left',      'name': 'Икра (левая)',           'unit': 'см'},
    {'key': 'calf_right',     'name': 'Икра (правая)',          'unit': 'см'},
    {'key': 'neck',           'name': 'Шея',                     'unit': 'см'},
  ];
}