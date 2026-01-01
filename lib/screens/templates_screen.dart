//lib/screens/templates_screen.dart

import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import 'edit_template_screen.dart';

class TemplatesScreen extends StatefulWidget{
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  // Временный список шаблонов
  final List<WorkoutTemplate> _templates = [
    WorkoutTemplate(
      id: '1',
      name: 'Тренировка груди',
      dayOfWeek: 'Понедельник',
      exercises: [
        Exercise(id: '1',
            name: 'Жим штанги лёжа',
            weight: 80,
            sets: 4,
            reps: 8),
        Exercise(id: '2',
            name: 'Разводка гантелей',
            weight: 20,
            sets: 3,
            reps: 10),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    WorkoutTemplate(
      id: '2',
      name: 'Тренировка  спины',
      dayOfWeek: 'Среда',
      exercises: [
        Exercise(id: '3',
            name: 'Тяга верхнего блока',
            weight: 60,
            sets: 4,
            reps: 8),
        Exercise(id: '4',
            name: 'Тяга нижнего блока',
            weight: 20,
            sets: 3,
            reps: 10),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои тренировки'),
        centerTitle: true,
      ),
      body: _templates.isEmpty
          ? _buildEmptyState()
          : _buildTemplatesList(),
      floatingActionButton: _buildAddButton(),
    );
  }

  // ПУСТОЕ СОСТОЯНИЕ
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'Нет тренировок',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          SizedBox(height: 8,),
          Text(
            'Нажмите + чтобы создать первую',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // СПИСОК ТРЕНИРОВОК
  Widget _buildTemplatesList() {
    return ListView.builder(
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(template.name),
            subtitle: Text('${template.dayOfWeek} - ${template.exercises
                .length} упражнений'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // КНОПКА РЕДАКТИРОВАНИЯ
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editTemplate(index),
                ),
                // КНОПКА УДАЛЕНИЯ
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteTemplate(index),
                ),
              ],
            ),
            onTap: () => _editTemplate(index),
          ),
        );
      },
    );
  }

  // КНОПКА ДОБАВЛЕНИЯ
  Widget _buildAddButton() {
    return FloatingActionButton(
      onPressed: _addTemplate,
      child: const Icon(Icons.add),
    );
  }

  // ДОБАВЛЕНИЕ ТРЕНИРОВКИ
  void _addTemplate() {
    final newTemplate = WorkoutTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Новая тренировка',
      dayOfWeek: 'Понедельник',
      exercises: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _templates.add(newTemplate);
    });
    // СРАЗУ ПЕРЕХОДИМ К РЕДАКТИРОВАНИЮ
    _editTemplate(_templates.length -1);
  }

  // РЕДАКТИРОВАНИЕ ТРЕНИРОВКИ
  void _editTemplate(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditTemplateScreen(
              template: _templates[index],
          ),
      ),
    ).then((updateTemplate) {
      if (updateTemplate != null) {
        setState((){
        _templates[index] = updateTemplate;
        });
      }
    });
  }

  // УДАЛЕНИЕ ТРЕНИРОВКИ
  void _deleteTemplate(int index) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Удалить тренировку?'),
            content: Text(
                'Вы уверены, что хотите удалить ${_templates[index].name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _templates.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red
                ),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
  }
}

