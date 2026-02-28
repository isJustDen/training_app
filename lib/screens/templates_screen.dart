//lib/screens/templates_screen.dart

import '../models/exercise.dart';
import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../services/storage_service.dart';
import 'edit_template_screen.dart';
import 'workout_screen.dart';
import 'stats_screen.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'settings_screen.dart';


class TemplatesScreen extends StatefulWidget{
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  // ЗАГРУЗКА СПИСКА ИЗ ХРАНИЛИЩА ШАБЛОНОВ

  List <WorkoutTemplate> _templates = [];
  bool _isLoading = true;

  // initState() - вызывается ПРИ СОЗДАНИИ виджета
  @override
  void initState(){
    super.initState();
    _loadTemplates(); // Загружаем данные при создании

    // ЗАГРУЖАЕМ НАСТРОЙКИ ПРИ ЗАПУСКЕ
    WidgetsBinding.instance.addPostFrameCallback((_){
      final settingsProvider = context.read<SettingsProvider> ();
      settingsProvider.loadSettings();
    });
  }

  // АСИНХРОННЫЙ МЕТОД ДЛЯ ЗАГРУЗКИ ДАННЫХ
  Future<void> _loadTemplates() async{
    setState(() {
      _isLoading = true; // Показываем индикатор загрузки
    });

    // ЗАГРУЖАЕМ ИЗ ХРАНИЛИЩА (может занять время)
    final loadedTemplates = await StorageService.loadTemplates();

    setState(() {
      _templates = loadedTemplates;
      _isLoading = false; // Скрываем индикатор загрузки
    });
  }

  // АСИНХРОННЫЙ МЕТОД ДЛЯ СОХРАНЕНИЯ ДАННЫХ
  Future<void> _saveTemplates() async{
    await StorageService.saveTemplates(_templates);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои тренировки'),
        centerTitle: true,
        actions: [
          // КНОПКА НАСТРОЕК
          IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              tooltip: 'Настройка',
          ),

          // КНОПКА СТАТИСТИКИ
          IconButton(
            onPressed: () => _openStats(),
            icon: const Icon(Icons.assessment),
            tooltip: 'Статистика',
          ),

          // КНОПКА ОБНОВЛЕНИЯ
          IconButton(
              onPressed: _loadTemplates,
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить',
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: _buildAddButton(),
    );
  }

  // ПОСТРОЕНИЕ КОНТЕНТА В ЗАВИСИМОСТИ ОТ СОСТОЯНИЯ
  Widget _buildContent(){
    // ЕСЛИ ИДЕТ ЗАГРУЗКА
    if (_isLoading){
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(), //Индикатор загрузки
            SizedBox(height: 16),
            Text('Загрузка тренировок...'),
          ],
        ),
      );
    }

    // ЕСЛИ СПИСОК ПУСТ
    if (_templates.isEmpty){
      return _buildEmptyState();
    }

    // ЕСЛИ ЕСТЬ ДАННЫЕ
    return _buildTemplatesList();
  }

  // ПУСТОЕ СОСТОЯНИЕ
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            'Нет тренировок',
            style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8,),
          Text(
            'Нажмите + чтобы создать первую',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                // КНОПКА ЗАПУСКА ТРЕНИРОВКИ
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.green),
                  onPressed: () => _startWorkout(template),
                    tooltip: 'Начать тренировку',
                ),

                // КНОПКА РЕДАКТИРОВАНИЯ
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editTemplate(index),
                ),

                // КНОПКА УДАЛЕНИЯ
                IconButton(
                  icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
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
  void _addTemplate() async{
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

    // СОХРАНЯЕМ ПОСЛЕ ДОБАВЛЕНИЯ
    await _saveTemplates();

    // ПЕРЕХОДИМ К РЕДАКТИРОВАНИЮ
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
    ).then((updateTemplate) async {
      if (updateTemplate != null) {
        setState((){
        _templates[index] = updateTemplate;
        });

        // СОХРАНЯЕМ ИЗМЕНЕНИЯ
        await _saveTemplates();
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
                onPressed: () async {
                  setState(() {
                    _templates.removeAt(index);
                  });

                  // СОХРАНЯЕМ ПОСЛЕ УДАЛЕНИЯ
                  await _saveTemplates();

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
  }

  // МЕТОД ДЛЯ ОЧИСТКИ ВСЕХ ДАННЫХ
  void _clearData() async{
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Очистите все данные?'),
          content: const Text('Это действие удалит все тренировки, Вы не сможете их восстановить'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
            ),
            ElevatedButton(
                onPressed: () async{
                // ОЧИЩАЕМ ХРАНИЛИЩЕ
                  await StorageService.clearAllData();

                  // ОЧИЩАЕМ ЛОКАЛЬНЫЙ СПИСОК
                  setState(() {
                    _templates.clear();
                  });

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,

                ),
                child: const Text('Очистить'),
            ),
          ],
        ),
    );
  }

  //МЕТОД ДЛЯ ЗАПУСКА ТРЕНИРОВКИ:
  void _startWorkout(WorkoutTemplate template){
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => WorkoutScreen(template: template),
      ),
    ).then((_) async {
      await _loadTemplates();
    });
  }

//МЕТОД СТАТИСТИКИ
  void _openStats(){
    // Собираем все упражнения из всех шаблонов
    List<Exercise> allExercises = [];
    for (var template in _templates) {
      allExercises.addAll(template.exercises);
    }
    // Убираем дубликаты по названию
    Map<String, Exercise> uniqueExercises = {};
    for (var exercise in allExercises){
      if (!uniqueExercises.containsKey(exercise.name)) {
        uniqueExercises[exercise.name] = exercise;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsScreen(
          currentExercises: uniqueExercises.values.toList(),
          ),
      ),
    );
  }
}

