// screens/workout_generator_screen.dart

import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../services/exercise_database.dart';
import '../services/storage_service.dart';
import 'dart:math';

// ЭКРАН ГЕНЕРАТОРА ТРЕНИРОВОК
class WorkoutGeneratorScreen  extends StatefulWidget{
  const WorkoutGeneratorScreen({super.key});

  @override
  State<WorkoutGeneratorScreen> createState() => _WorkoutGeneratorScreenState();
}

class _WorkoutGeneratorScreenState extends State<WorkoutGeneratorScreen> {

  // ВЫБРАННЫЕ ГРУППЫ МЫШЦ
  final Set<MuscleGroup> _selectedGroups = {};

  // КОЛИЧЕСТВО УПРАЖНЕНИЙ
  int _exerciseCount = 5;

  // СГЕНЕРИРОВАННЫЕ УПРАЖНЕНИЯ (результат)
  List<Exercise> _generatedExercises = [];

  // ФЛАГ — показываем результат или форму выбора
  bool _showResult = false;

  final _random = Random();

  // ПЕРЕКЛЮЧЕНИЕ ГРУППЫ МЫШЦ
  void _toggleGroup(MuscleGroup group) {
    setState((){
      if (_selectedGroups.contains(group)) {
        _selectedGroups.remove(group);
      } else {
        _selectedGroups.add(group);
      }
      // Сбрасываем результат при изменении выбора
      _showResult = false;
      _generatedExercises = [];
    });
  }

  // ГЕНЕРАЦИЯ ТРЕНИРОВКИ
  void _generate() {
    if (_selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите хотя бы одну группу мышц'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Получаем подходящие упражнения из базы
    final candidates = ExerciseDatabase.getByMyscleGroups(
        _selectedGroups.toList());

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет упражнений для выбранных мышц')),
      );
      return;
    }

    // Перемешиваем — shuffle изменяет список на месте случайным образом
    final shuffled = List.from(candidates)
      ..shuffle(_random);

    // Берём не больше чем запрошено и не больше чем есть
    final count = min(_exerciseCount, shuffled.length);

    setState(() {
      _generatedExercises = List.generate(count, (i) {
        final template = shuffled[i];
        // Создаём Exercise из шаблона с дефолтными параметрами
        return Exercise(
          id: '${DateTime
              .now()
              .millisecondsSinceEpoch}_$i',
          name: template.name,
          muscleGroups: template.muscleGroups,
          // Стандартные параметры — пользователь изменит в редакторе
          weight: 0,
          sets: 3,
          reps: 8,
          restTime: 60,
        );
      });
      _showResult = true;
    });
  }
  void _regenerate() => _generate();

  Future<void> _saveAsTemplate() async {
    final name = await _showNameDialog();
    if (name == null || name.isEmpty) return;

    final now = DateTime.now();
    final template = WorkoutTemplate(
        id: now.millisecondsSinceEpoch.toString(),
        name: name, dayOfWeek: '',
        exercises: _generatedExercises,
        createdAt: now,
        updatedAt: now,
    );

    final templates = await StorageService.loadTemplates();
    templates.add(template);
    await StorageService.saveTemplates(templates);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Тренировка "$name" сохранена'),
        backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, template);
    }
  }

  // ДИАЛОГ ВВОДА НАЗВАНИЯ
  Future<String?> _showNameDialog() {
    final controller = TextEditingController(
      text: 'Тренировка ${_selectedGroups.map((g) => MuscleGroupInfo.getName(g)).join(', ')}'
    );

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Название тренировки'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Генератор тренировки'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1. Выберите группы мышц'),
            const SizedBox(height: 12,),
            _buildMuscleGroupGrid(),

            const SizedBox(height: 24,),

            _buildSectionHeader('2. Количество упражнений'),
            const SizedBox(height: 8,),
            _buildCountSelector(),

            const SizedBox(height: 24,),

            // КНОПКА ГЕНЕРАЦИИ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                  onPressed: _selectedGroups.isEmpty ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Сгенерировать тренировку'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
              ),
            ),

            // РЕЗУЛЬТАТ (показывается после генерации)
            if (_showResult) ... [
              const SizedBox(height: 24,),
              _buildResult(),
            ],
          ],
        ),
      ),
    );
  }

  // ЗАГОЛОВОК СЕКЦИИ
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  // СЕТКА ГРУПП МЫШЦ
  Widget _buildMuscleGroupGrid(){
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MuscleGroup.values.map((group) {
          final isSelected = _selectedGroups.contains(group);
          return GestureDetector(
           onTap: () => _toggleGroup(group),
           child: AnimatedContainer(
             duration: const Duration(milliseconds: 200),
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: isSelected
                   ? Theme.of(context).colorScheme.primary
                   : Colors.transparent,
               borderRadius: BorderRadius.circular(20),
               border: Border.all(
                 color: Theme.of(context).colorScheme.primary,
                 width: isSelected ? 0 : 1,
               ),
             ),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(MuscleGroupInfo.getEmoji(group)),
                 const SizedBox(width: 6,),
                 Text(
                   MuscleGroupInfo.getName(group),
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.w600,
                     color: isSelected
                       ? Colors.white
                       : Theme.of(context).colorScheme.primary
                   ),
                 ),
               ],
             ),
           ),
         );
        }).toList(),
    );
  }

  // ВЫБОР КОЛИЧЕСТВА УПРАЖНЕНИЙ
  Widget _buildCountSelector(){
    return Row(
      children: [
        // Слайдер для выбора числа
        Expanded(
            child: Slider(
              value: _exerciseCount.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              label: '$_exerciseCount упр.',
              onChanged: (val) => setState(() => _exerciseCount = val.round()),
            ),
        ),
        // Числовой индикатор
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$_exerciseCount',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // РЕЗУЛЬТАТ ГЕНЕРАЦИИ
  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSectionHeader('Сгенерированная тренировка'),
            const Spacer(),
            // Кнопка перегенерации
            TextButton.icon(
              onPressed: _regenerate,
              icon: const Icon(Icons.refresh, size: 16,),
              label: const Text('Ещё раз'),
            ),
          ],
        ),
        const SizedBox(height: 8,),
        // СПИСОК УПРАЖНЕНИЙ
        ...List.generate(_generatedExercises.length, (i) {
          final ex = _generatedExercises[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              // Номер упражнения в кружке
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                radius: 16,
                child: Text('${i+1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: ex.muscleGroups.isEmpty
                ? null
                : Text(
                ex.muscleGroups
                  .map((g) => '${MuscleGroupInfo.getEmoji(g)} ${MuscleGroupInfo.getName(g)}')
                  .join('  '),
                style: const TextStyle(fontSize: 11),
            ),
              // Кнопка удаления конкретного упражнения из результата
              trailing: IconButton(
                  onPressed: () => setState(() => _generatedExercises.removeAt(i)),
                  icon: const Icon(Icons.close, size: 18,)),
            ),
          );
        }),

        const SizedBox(height: 16,),

        // КНОПКА СОХРАНЕНИЯ
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
              onPressed: _saveAsTemplate,
              icon: const Icon(Icons.save),
              label: const Text('Сохранить как тренировку'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
          ),
        ),
      ],
    );
  }
}