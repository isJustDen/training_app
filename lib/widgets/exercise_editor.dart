//widgets/exercise_editor.dart

import 'package:flutter/material.dart';
import '../models/exercise.dart';

// Виджет для редактирования одного упражнения
// StatelessWidget потому что сам не хранит состояние

class ExerciseEditor extends StatelessWidget{
  final Exercise exercise;
  final Function(Exercise) onSave;
  final VoidCallback onCancel;

  // Контроллеры для полей ввода
  final TextEditingController nameController;
  final TextEditingController weightController;
  final TextEditingController setsController;
  final TextEditingController repsController;
  final TextEditingController restController;

  // КОНСТРУКТОР с инициализацией
  ExerciseEditor({
    super.key,
    required this.exercise,
    required this.onSave,
    required this.onCancel,
  }):
// Инициализируем контроллеры в списке инициализаторов
    nameController = TextEditingController(text: exercise.name),
    weightController = TextEditingController(text:exercise.weight.toString()),
    setsController = TextEditingController(text:exercise.sets.toString()),
    repsController = TextEditingController(text:exercise.reps.toString()),
    restController = TextEditingController(text:(exercise.restTime ~/ 60).toString());

  @override

  Widget build(BuildContext context){
    return AlertDialog(
      title: const Text('Редактировать упражнение'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ПОЛЕ ДЛЯ НАЗВАНИЯ
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название упражнения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center, color: Colors.lightBlue,)
              ),
            ),
            const SizedBox(height: 16),

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
                const SizedBox(width: 20, height: 20),

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
            const SizedBox(width: 20, height: 20),

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
                const SizedBox(width: 20, height: 20),

                // ОТДЫХ
                Expanded(
                  child: TextField(
                    controller: restController,
                    decoration: const InputDecoration(
                      labelText: 'Отдых(мин)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        // КНОПКА ОТМЕНЫ
        TextButton(
            onPressed: onCancel,
            child: const Text('Отмена'),
        ),
        
        // КНОПКА СОХРАНЕНИЯ
        ElevatedButton(
            onPressed: () => _handleSave(context),
            child: const Text('Сохранить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent
            ),
        ),
      ],
    );
  }

  // ОБРАБОТЧИК СОХРАНЕНИЯ
  void _handleSave(BuildContext context){
    // ПРОВЕРКА ВАЛИДНОСТИ
    if (nameController.text.isEmpty){
      _showError(context, 'Введите название упражнения');
      return;
    }

    // ПАРСИМ ЧИСЛА
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final sets = int.tryParse(setsController.text) ?? 3;
    final reps = int.tryParse(restController.text) ?? 8;
    final restMinutes = int.tryParse(restController.text) ?? 1;

    // ПРОВЕРКА НА ПОЛОЖИТЕЛЬНЫЕ ЗНАЧЕНИЯ
    if (weight < 0){
      _showError(context, 'Вес не может быть отрицательным');
      return;
    }
    if (sets <=0){
      _showError(context, 'Количество подходов должно быть больше 0');
      return;
    }

    if (reps <= 0){
      _showError(context, 'Количество повторений должно быть больше 0');
      return;
    }

    final updatedExercise = exercise.copyWith(
      name: nameController.text,
      weight: weight,
      sets: sets,
      reps: reps,
      restTime: restMinutes * 60,
    );

    // ВЫЗЫВАЕМ КОЛБЭК
    onSave(updatedExercise);

    // ЗАКРЫВАЕМ ДИАЛОГ
    Navigator.pop(context);
  }

  // ПОКАЗАТЬ ОШИБКУ
  void _showError(BuildContext context, String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}