//lib/screens/edit_template_screen.dart

import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import '../widgets/exercise_editor.dart';

// Экран для редактирования шаблона тренировки
class EditTemplateScreen extends StatefulWidget{
  final WorkoutTemplate template;

  const EditTemplateScreen({
    super.key,
    required this.template,
});

  @override
  State<EditTemplateScreen> createState() => _EditTemplateScreenState();
}

class _EditTemplateScreenState extends State<EditTemplateScreen>{
  // Локальная копия шаблона для редактирования
  late WorkoutTemplate _template;

// Контроллеры для полей ввода
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dayController = TextEditingController();

  @override

  void initState(){
    super.initState();
    // Создаем копию шаблона для редактирования
    // (чтобы не менять оригинал до сохранения)
    _template = widget.template.copyWith();

    // Заполняем контроллеры текущими значениями
    _nameController.text = _template.name;
    _dayController.text = _template.dayOfWeek;
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование тренировки'),
        actions: [
          IconButton(
            icon:  const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Сохранить',
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
          onPressed: _addExercise,
          child: const Icon(Icons.add),
      ),
    );
  }

// МЕТОД ДЛЯ ПОСТРОЕНИЯ ОСНОВНОГО СОДЕРЖИМОГО
  Widget _buildBody(){
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ЗАГОЛОВОК И ОПИСАНИЕ
          _buildHeader(),
          const SizedBox(height: 24),

          // ПОЛЯ ДЛЯ РЕДАКТИРОВАНИЯ
          _buildEditFields(),
          const SizedBox(height: 24),

          // СПИСОК УПРАЖНЕНИЙ
          _buildExercisesList(),
        ],
      ),
    );
  }

  // Заголовок
  Widget _buildHeader(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Редактируем тренировку',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'ID ${_template.id}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // ПОЛЯ РЕДАКТИРОВАНИЯ
  Widget  _buildEditFields(){
    return Column(
      children: [
        // НАЗВАНИЕ ТРЕНИРОВКИ
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Название тренировки',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
          onChanged: (value){
            setState(() {
              _template = _template.copyWith(name: value);
            });
          }
        ),
        const SizedBox(height: 16),

        // ДЕНЬ НЕДЕЛИ
        TextField(
          controller: _dayController,
          decoration: InputDecoration(
            labelText: 'День недели',
            border:OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
          onChanged: (value){
            setState(() {
              _template = _template.copyWith(dayOfWeek: value);
            });
          },
        ),
      ],
    );
  }

  // СПИСОК УПРАЖНЕНИЙ
  Widget _buildExercisesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Упражнения:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${_template.exercises.length}'),
              backgroundColor: Colors.green.shade200,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ЕСЛИ УПРАЖНЕНИЙ НЕТ
        if (_template.exercises.isEmpty)
          _buildEmptyExercises(),

        // ЕСЛИ УПРАЖНЕНИЯ ЕСТЬ
        if (_template.exercises.isNotEmpty)
          ..._template.exercises.asMap().entries.map((entry){
          final index = entry.key;
          final exercise = entry.value;
          return _buildExerciseCard(exercise, index);
          }),
      ],
    );
  }

  // ПУСТОЙ СПИСОК УПРАЖНЕНИЙ
  Widget _buildEmptyExercises(){
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.deepPurple.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_run, size: 48, color: Colors.grey,),
          const SizedBox(height: 16),
          const Text(
            'Нет упражнений',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text(
            'Нажмите + чтобы добваить упражнение',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize:20, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // КАРТОЧКА УПРАЖНЕНИЯ
  Widget _buildExerciseCard(Exercise exercise, int index){
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child:Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // НОМЕР УПРАЖНЕНИЯ
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // НАЗВАНИЕ
                Expanded(
                    child: Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ),

                // КНОПКИ ДЕЙСТВИЙ
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // КНОПКА РЕДАКТИРОВАНИЯ
                    IconButton(
                      onPressed: () => _editExercise(index),
                      icon: const Icon(Icons.edit, size: 20,),
                      tooltip: 'Редактировать',
                    ),

                    // КНОПКА УДАЛЕНИЯ
                    IconButton(
                        onPressed: () => _removeExercise(index),
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        tooltip: 'Удалить',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ИНФОРМАЦИЯ ОБ УПРАЖНЕНИИ
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ПАРАМЕТРЫ
                  Row(
                    children: [
                      _buildParamChip('${exercise.weight}  kg', Icons.fitness_center),
                      const SizedBox(width: 5),
                      _buildParamChip('${exercise.sets}  set', Icons.repeat),
                      const SizedBox(width: 5),
                      _buildParamChip('${exercise.reps} rep', Icons.repeat_one),
                      const SizedBox(width: 5),
                      _buildParamChip('${exercise.restTime ~/ 60} m', Icons.timer),
                      const SizedBox(width: 5),
                    ],

                  ),

                  // РАСЧЕТ ОБЪЕМА (добавим позже)
                  if (exercise.weight > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Объём ${exercise.weight * exercise.sets * exercise.reps} единиц',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ЧИП С ПАРАМЕТРОМ
  Widget _buildParamChip(String text, IconData icon){
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, fontWeight: FontWeight.bold,),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
      // backgroundColor: Colors.grey.shade600,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  // ДОБАВЛЕНИЕ УПРАЖНЕНИЯ
  void _addExercise(){
    final newExercise = Exercise(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Новое упражнение',
    );

    setState((){
      _template.addExercise(newExercise);
    });

    // СРАЗУ ОТКРЫВАЕМ РЕДАКТИРОВАНИЕ
    _editExercise(_template.exercises.length - 1);
  }

  // РЕДАКТИРОВАНИЕ УПРАЖНЕНИЯ
  void _editExercise(int index){

    showDialog(
        context: context,
        builder: (context) {
          return ExerciseEditor(
            exercise: _template.exercises[index],
            onSave: (updatedExercise){
              // ОБНОВЛЯЕМ УПРАЖНЕНИЕ В СПИСКЕ
              setState(() {
                _template.exercises[index] = updatedExercise;
              });
            },
            onCancel: (){
              Navigator.pop(context);
            },
          );
        },
    );
  }

  // УДАЛЕНИЕ УПРАЖНЕНИЯ
  void _removeExercise(int index){
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить упражнение?'),
          content: Text('Вы уверены, что хотите удалить "${_template.exercises[index].name}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
            ),
            ElevatedButton(
                onPressed: (){
                  setState(() {
                    _template.removeExercise(index);
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                ),
                child: const Text('Удалить'),
            ),
          ],
        ),
    );
  }

  // СОХРАНЕНИЕ ИЗМЕНЕНИЙ
  void _saveChanges(){
    // ПРОВЕРКА ВАЛИДНОСТИ
    if (_nameController.text.isEmpty){
      _showError('Введите название тренировки');
      return;
    }
    if (_dayController.text.isEmpty){
      _showError('Введите день недели');
      return;
    }

    // СОЗДАЕМ ОБНОВЛЕННУЮ ВЕРСИЮ ШАБЛОНА
    final updatedTemplate = _template.copyWith(
      updatedAt: DateTime.now(),
    );

    // ЗДЕСЬ ПОЗЖЕ БУДЕМ СОХРАНЯТЬ В БАЗУ ДАННЫХ
    print('Сохранено ${_template.name}');

    // ВОЗВРАЩАЕМСЯ НАЗАД
    Navigator.pop(context, updatedTemplate);
  }

  // ПОКАЗАТЬ ОШИБКУ
  void _showError(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text (message),
          backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose(){
    // Важно очищать контроллеры при удалении виджета
    _nameController.dispose();
    _dayController.dispose();
    super.dispose();
  }
}