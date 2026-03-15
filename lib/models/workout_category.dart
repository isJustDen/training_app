//models/workout_category.dart

class WorkoutCategory{
  final String id;
  final String name;
  final String emoji;
  final String color;
  final List<WorkoutGroup> groups;
  final DateTime createdAt;

  WorkoutCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.groups,
    required this.createdAt,
  });

  WorkoutCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    String? color,
    List<WorkoutGroup>? groups,
    DateTime? createdAt,
  }) {
    return WorkoutCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        color: color ?? this.color,
        groups: groups ?? this.groups,
        createdAt: createdAt ?? this.createdAt,
    );
  }

  // СЕРИАЛИЗАЦИЯ В MAP
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'color': color,
      'groups': groups.map((g) => g.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // ДЕСЕРИАЛИЗАЦИЯ ИЗ MAP
  factory WorkoutCategory.fromMap(Map<String, dynamic> map) {
    return WorkoutCategory(
        id: map['id'],
        name: map['name'],
        emoji: map['emoji'] ?? '💪',
        color: map['color']??'#FF2979FF',
        groups: (map['groups'] as List? ?? [])
            .map((g) => WorkoutGroup.fromMap(g))
            .toList(),
        createdAt: DateTime.parse(map['createdAt'])
    );
  }
}

// ГРУППА ТРЕНИРОВОК внутри категории
class WorkoutGroup{
  final String id;
  final String name;
  final List<String> templateIds;
  
  WorkoutGroup({
    required this.id,
    required this.name,
    required this.templateIds,
  });
  
  WorkoutGroup copyWith({
    String? id,
    String? name,
    List<String>? templateIds,
  }){
    return WorkoutGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      templateIds: templateIds ?? this.templateIds,
    );
  }
  
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'templateIds': templateIds,
  };
  
  factory WorkoutGroup.fromMap(Map<String, dynamic> map) {
    return WorkoutGroup(
      id: map['id'],
      name: map['name'],
      templateIds: List<String>.from(map['templateIds'] ?? []),
    );
  }
}