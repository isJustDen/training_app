//lib/screens/templates_screen.dart

import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';

class TemplatesScreen extends StatefulWidget{
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  // Временный список шаблонов
  final  List<WorkoutTemplate> _templates = [
    WorkoutTemplate(
        id: '1',
        name: 'Тренировка груди',
        dayOfWeek: 'Понедельник',
        exercises: [
          Exercise(id: '1', name: 'Жим штанги лёжа', weight: 80, sets: 4, reps: 8),
          Exercise(id: '2', name: 'Разводка гантелей', weight: 20, sets: 3, reps: 10),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
    ),
    WorkoutTemplate(
      id: '2',
      name: 'Тренировка  спины',
      dayOfWeek: 'Среда',
      exercises: [
          Exercise(id: '3', name: 'Тяга верхнего блока', weight: 60, sets: 4, reps: 8),
          Exercise(id: '4', name: 'Тяга нижнего блока', weight: 20, sets: 3, reps: 10),
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
      ),
      body: ListView.builder(
        itemCount:  _templates.length,
        itemBuilder: (context, index){
          final template = _templates[index];
          return Card(
           margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(template.name),
            subtitle: Text('${template.dayOfWeek} - ${template.exercises.length} упражнений'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: (){
                setState(() {
                  _templates.removeAt(index);
                });
              },
            ),
            onTap: () {
              print('Нажали на: ${template.name}');
            },
          ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            setState(() {
              _templates.add(
                WorkoutTemplate(
                    id: '${_templates.length + 1}',
                    name: 'Новая тренировка ${_templates.length + 1}',
                    dayOfWeek: 'Пятница',
                    exercises: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                ),
              );
            });
          },
          child: const Icon(Icons.add),
      ),
    );
  }
}