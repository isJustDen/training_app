//widgets/exercise_editor.dart

import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/exercise_database.dart';

// Виджет для редактирования одного упражнения

class ExerciseEditor extends StatefulWidget {
  final Exercise exercise;
  final Function(Exercise) onSave;
  final VoidCallback onCancel;

  // КОНСТРУКТОР с инициализацией
  const ExerciseEditor({
    super.key,
    required this.exercise,
    required this.onSave,
    required this.onCancel,
  });
  @override
  State<ExerciseEditor> createState() => _ExerciseEditorState();
}

class _ExerciseEditorState extends State<ExerciseEditor> {

  // Инициализируем контроллеры в списке инициализаторов
  late TextEditingController nameController;
 late TextEditingController weightController;
 late TextEditingController setsController;
 late TextEditingController repsController;
 late TextEditingController restController;
 late bool _isTimeBased;
 late TextEditingController targetSecondsController;

 // ПОДСКАЗКИ АВТОДОПОЛНЕНИЯ
 List<_ExerciseTemplate_local> _suggestions = [];

 // ВЫБРАННЫЕ ГРУППЫ МЫШЦ
  late List<MuscleGroup> _selectedMuscleGroups;

  // ТЕКСТ ОШИБКИ ВАЛИДАЦИИ
  String? _errorText;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.exercise.name);
    weightController = TextEditingController(text: widget.exercise.weight.toString());
    setsController = TextEditingController(text: widget.exercise.sets.toString());
    repsController= TextEditingController(text: widget.exercise.reps.toString());
    restController = TextEditingController(text: widget.exercise.restTime.toString());

    // Копируем текущие мышцы упражнения
    _selectedMuscleGroups = List.from(widget.exercise.muscleGroups);

    // Подписываемся на изменения поля имени — показываем подсказки
    nameController.addListener(_onNameChanged);

    _isTimeBased = widget.exercise.isTimeBased;
    targetSecondsController = TextEditingController(
      text: widget.exercise.targetSeconds.toString()
    );
  }

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    nameController.dispose();
    weightController.dispose();
    setsController.dispose();
    repsController.dispose();
    restController.dispose();
    targetSecondsController.dispose();
    super.dispose();
  }

  // ОБРАБОТЧИК ИЗМЕНЕНИЯ ИМЕНИ
  void _onNameChanged() async {
    if(!mounted) return;
    final results = await ExerciseDatabase.searchAsync(nameController.text);

    if (!mounted) return;

    setState(() {
      // Приводим к локальному типу чтобы не тащить приватный класс наружу
      _suggestions = results
          .map((t) => _ExerciseTemplate_local(t.name, t.muscleGroups))
          .toList();
    });
  }

  // ВЫБОР ПОДСКАЗКИ
  void _applySuggestion(_ExerciseTemplate_local suggestion) {
    setState(() {
      nameController.text = suggestion.name;
      // Устанавливаем курсор в конец строки
      nameController.selection = TextSelection.fromPosition(
        TextPosition(offset: nameController.text.length),
      );
      _selectedMuscleGroups = List.from(suggestion.muscleGroups);
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context){
    return AlertDialog(
      title: const Text('Редактировать упражнение'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ПОКАЗЫВАЕМ ОШИБКУ ЕСЛИ ЕСТЬ
            if (_errorText != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8,),
                    Expanded(
                        child: Text(
                          _errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            fontSize: 13,
                          ),
                        ),
                    ),
                  ],
                ),
              ),
            // ПОЛЕ ДЛЯ НАЗВАНИЯ C АВТОДОПОЛНЕНИЕМ
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название упражнения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center, color: Colors.lightBlue,)
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Text('Тип: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
                  ),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                    segments: const[
                      ButtonSegment(
                        value: false,
                        label: Text('Повтор.'),
                        icon: Icon(Icons.repeat_rounded, size: 12)
                      ),
                      ButtonSegment(
                          value: true,
                          label: Text('Время'),
                          icon: Icon(Icons.timer_rounded, size: 12)
                      ),
                    ],
                    selected: {_isTimeBased},
                    onSelectionChanged: (value){
                      setState(() => _isTimeBased = value.first);
                    },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_isTimeBased) ... [
              TextField(
                controller: targetSecondsController,
                decoration: const InputDecoration(
                  labelText: 'Целевое время (сек)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer_rounded),
                  hintText: 'Например: 60 (1 минута)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8,),
              // ПОДСКАЗКА — показываем в минутах
              Builder(builder: (context){
                final secs = int.tryParse(targetSecondsController.text) ?? 0;
                final mins = secs ~/ 60;
                final rem = secs % 60;
                final label = mins > 0
                  ? '$mins мин ${rem > 0? "$rem сек": ""}'
                  : '$secs сек';
                return Text(
                  'выбранное время = $label',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              }),
            ] else ...[
              // СТРОКА С ВЕСОМ И ПОДХОДАМИ
              Row(
                children: [
                  // ВЕС
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      decoration: const InputDecoration(
                        labelText: 'Вес (кг)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ПОДХОДЫ
                  Expanded(
                    child: TextField(
                      controller: setsController,
                      decoration: const InputDecoration(
                        labelText: 'Подходы',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // СТРОКА С ПОВТОРЕНИЯМИ И ОТДЫХОМ
              Row(
                children: [
                  // ПОВТОРЕНИЯ
                  Expanded(
                    child: TextField(
                      controller: repsController,
                      decoration: const InputDecoration(
                        labelText: 'Повторения',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ОТДЫХ
                  Expanded(
                    child: TextField(
                      controller: restController,
                      decoration: const InputDecoration(
                        labelText: 'Отдых(сек)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],


            // СПИСОК ПОДСКАЗОК (появляется при вводе)
            if (_suggestions.isNotEmpty) ... [
              const SizedBox(height: 4,),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _suggestions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(s.name, style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            s.muscleGroups.map((g) => MuscleGroupInfo.getEmoji(g)).join(' '),
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () => _applySuggestion(s),
                        ),
                        // Разделитель между элементами (кроме последнего)
                        if (i < _suggestions.length - 1)
                          const Divider(height: 1),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 16),


          ],
        ),
      ),
      actions: [
        // КНОПКА ОТМЕНЫ
        TextButton(
            onPressed: widget.onCancel,
            child: const Text('Отмена'),
        ),

        // КНОПКА СОХРАНЕНИЯ
        ElevatedButton(
            onPressed: () => _handleSave(context),
            child: const Text('Сохранить'),
        ),
      ],
    );
  }

  // ОБРАБОТЧИК СОХРАНЕНИЯ
  void _handleSave(BuildContext context) async {
    // СБРАСЫВАЕМ ПРЕДЫДУЩУЮ ОШИБКУ
    setState(() => _errorText = null);

    // ПРОВЕРКА ИМЕНИ
    if (nameController.text.isEmpty){
      setState(() => _errorText = 'Введите название упражнения');
      return;
    }

    final targetSeconds = int.tryParse(targetSecondsController.text) ?? 30;

    // ПАРСИМ ЧИСЛА
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final sets = int.tryParse(setsController.text) ?? 3;
    final reps = int.tryParse(repsController.text) ?? 8;
    final restSeconds = int.tryParse(restController.text) ?? 60;

    // ПРОВЕРКА НА ПОЛОЖИТЕЛЬНЫЕ ЗНАЧЕНИЯ
    if ( sets <=0 || reps <= 0){
      setState(() => _errorText = 'Подходы и повторения должны быть больше 0');
      return;
    }

    final updated = widget.exercise.copyWith(
      name: nameController.text,
      weight: weight,
      sets: sets,
      reps: reps,
      restTime: restSeconds,
      muscleGroups: _selectedMuscleGroups,
      targetSeconds: targetSeconds,
      isTimeBased: _isTimeBased,
    );

    // СОХРАНЯЕМ В ЛИЧНУЮ БАЗУ
    await ExerciseDatabase.saveUserExercise(
    nameController.text,
    _selectedMuscleGroups.isEmpty
      ? [MuscleGroup.other]
      : _selectedMuscleGroups,
    );

    // ВЫЗЫВАЕМ КОЛБЭК
    widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }
}

// Локальный вспомогательный класс — зеркало приватного _ExerciseTemplate
class _ExerciseTemplate_local {
  final String name;
  final List<MuscleGroup> muscleGroups;
  _ExerciseTemplate_local(this.name, this.muscleGroups);
}