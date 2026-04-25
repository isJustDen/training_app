//lib/screens/templates_screen.dart

import 'package:fitflow/screens/workout_generator_screen.dart';

import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../services/storage_service.dart';
import 'edit_template_screen.dart';
import 'workout_screen.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';


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
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: _buildAddButton(),
    );
  }

  // НОВЫЙ КРАСИВЫЙ ХЕДЕР вместо AppBar
  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8)
            ],
        ),
      ),
      child: SafeArea(
        bottom: false,
          child: Padding(
              padding: const EdgeInsetsGeometry.fromLTRB(20, 8, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // СТРОКА: Заголовок + кнопки действий
                Row(
                  children: [
                    // ЗАГОЛОВОК
                    Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Мои тренировки',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_templates.length} шаблонов',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                    ),

                    // КНОПКИ ДЕЙСТВИЙ в хедере
                    _buildHeaderAction(
                      icon: Icons.auto_awesome_rounded,
                      tooltip: 'Генератор',
                      onTap: _openGenerator,
                    ),

                    SizedBox(width: 8),

                    _buildHeaderAction(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Обновить',
                      onTap: _loadTemplates,
                    ),

                  ],
                ),
              ],
            ),
          ),
      ),
    );
  }

  // КНОПКА В ХЕДЕРЕ — полупрозрачная
  Widget _buildHeaderAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // МЕТОД ГЕНЕРАТОРА
  void _openGenerator() async {
    final newTemplate = await Navigator.push<WorkoutTemplate>(
      context,
      MaterialPageRoute(builder: (_)=> const WorkoutGeneratorScreen()),
    );
    if(newTemplate != null) _loadTemplates();
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
      padding: const EdgeInsets.only(bottom: 80),
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
}

