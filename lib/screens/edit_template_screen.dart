//lib/screens/edit_template_screen.dart

import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../models/exercise.dart';
import '../widgets/exercise_editor.dart';
import '../utils/circle_utils.dart';

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

  List<int> _selectedExerciseIndices = []; // Для multi-select
  bool _isSelectionMode = false; // Режим выбора упражнений для круга

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
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
  // МЕТОД ОБНОВЛЁН ДЛЯ ПОДДЕРЖКИ КРУГОВ
  Widget _buildExercisesList() {
    final exercises = _template.exercises;
    final circles = CircleUtils.groupExercisesByCircle(exercises);
    final circleNumbers = CircleUtils.getAllCircleNumbers(exercises);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ЗАГОЛОВОК С КНОПКАМИ УПРАВЛЕНИЯ
        Row(
          children: [
            Text(
              'Упражнения:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            ),
            const Spacer(),

            // КНОПКА СОЗДАНИЯ КРУГА
            if(!_isSelectionMode && exercises.length >=2)
              ElevatedButton.icon(
                onPressed: _toggleSelectionMode,
                label: const Text('Создать круг'),
                icon: const Icon(Icons.group_add),
                style: ElevatedButton.styleFrom(
                    backgroundColor:  Colors.blue,
                    foregroundColor: Colors.white,
                ),
              ),

            // КНОПКА ПОДТВЕРЖДЕНИЯ ВЫБОРА
            if (_isSelectionMode && _selectedExerciseIndices.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _createCircleFromSelected,
                icon: const Icon(Icons.done),
                label: Text('Создать (${_selectedExerciseIndices.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            const SizedBox(width: 8),
            Chip(
              label: Text('${_template.exercises.length}',),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide(
                color: Colors.green.shade900
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // СПИСОК КРУГОВ (если есть)
        if (circleNumbers.isNotEmpty) ... [
          ...circleNumbers.map((circleNumber){
            final circleExercises = circles[circleNumber]!;
            final color = CircleUtils.getCircleColor(circleNumber);

            return _buildCircleCard(circleNumber, circleExercises, color);
          }),
          const SizedBox(height: 16),
        ],

        // ОТДЕЛЬНЫЕ УПРАЖНЕНИЯ (не в кругах)
        Text('Отдельные упражнения',
        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary,
        )),
        const SizedBox(height: 8),

      if(exercises.where((e) => !e.isInAnyCircle).isEmpty)
          _buildEmptyExercises(),

        // УПРАЖНЕНИЯ НЕ В КРУГАХ
        ...exercises.asMap().entries.where((entry) {
          return !entry.value.isInAnyCircle;
        }).map((entry){
        final index = entry.key;
        final exercise = entry.value;
        return _buildExerciseCard(exercise, index,true);
        }),
      ],
    );
  }

  // ПУСТОЙ СПИСОК УПРАЖНЕНИЙ
  Widget _buildEmptyExercises(){
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.directions_run, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Нет упражнений',
            style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(
            'Нажмите + чтобы добваить упражнение',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize:20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // КАРТОЧКА УПРАЖНЕНИЯ С ПОДДЕРЖКОЙ ВЫБОРА
  Widget _buildExerciseCard(Exercise exercise, int index, bool isInCircle){
    final isSelected = _selectedExerciseIndices.contains(index);
    final circleColor = exercise.isInAnyCircle
      ? CircleUtils.getCircleColor(exercise.circleNumber)
        : null;

    return Card(
      margin: EdgeInsets.only(
        bottom: 8.0,
        left: isInCircle ? 16.0 : 0,
      ),
      color: isSelected
        ? Colors.blue.withOpacity(0.1)
          : (circleColor?.withOpacity(0.05) ?? Theme.of(context).colorScheme.outline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected
              ? Colors.blue
              : (circleColor?.withOpacity(0.3) ?? Colors.green.shade900),
          width: isSelected ? 2:1,
        ),
      ),
      child: ListTile(
        leading: _buildExerciseLeading(exercise, index, isSelected),
        title: Text(
          exercise.name,
          style: TextStyle(
            fontWeight: exercise.isInAnyCircle ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${exercise.sets}х${exercise.reps} по ${exercise.weight}кг'),
            if(exercise.isInAnyCircle)
              Text(
                'Круг ${exercise.circleNumber} (${exercise.circleOrder})',
                style: TextStyle(
                  fontSize: 11,
                  color: circleColor,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(_isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleExerciseSelection(index)
              ),

            // КНОПКА РЕДАКТИРОВАНИЯ
            IconButton(
              onPressed: () => _editExercise(index),
              icon: const Icon(Icons.edit, size: 20,),
              tooltip: 'Редактировать',
            ),

            // КНОПКА УДАЛЕНИЯ
            IconButton(
                onPressed: () => _removeExercise(index),
                icon: Icon(Icons.delete, size: 20, color: Theme.of(context).colorScheme.error),
                tooltip: 'Удалить',
            ),
          ],
        ),
        onTap: _isSelectionMode
          ? () => _toggleExerciseSelection(index)
          : null,
      ),
    );
  }

  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ LEADING В ЛИСТАЙЛЕ
  Widget _buildExerciseLeading(Exercise exercise, int index, bool isSelected){
    if (_isSelectionMode) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Theme.of(context).colorScheme.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            (index + 1).toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
    }

    // ЕСЛИ УПРАЖНЕНИЕ В КРУГЕ - ПОКАЗЫВАЕМ ИКОНКУ КРУГА
    if (exercise.isInAnyCircle){
      final color = CircleUtils.getCircleColor(exercise.circleNumber);
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2,),
        ),
        child: Center(
          child: Text(
            exercise.circleOrder.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      );
    }

    // ОБЫЧНОЕ УПРАЖНЕНИЕ
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (index + 1).toString(),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
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

  // НОВЫЙ МЕТОД ДЛЯ СОЗДАНИЯ КАРТОЧКИ КРУГА
  Widget _buildCircleCard(int circleNumber, List<Exercise> exercises, Color color){
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ЗАГОЛОВОК КРУГА С КНОПКОЙ УДАЛЕНИЯ
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration:  BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CircleUtils.getCircleIcon(circleNumber),
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text('Круг $circleNumber',
                        style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${exercises.length} ${CircleUtils.getExerciseWord(exercises.length)}',
                  style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                    onPressed:() => _removeCircle(circleNumber),
                    icon: Icon(Icons.delete, size: 18, color: Theme.of(context).colorScheme.error),
                    tooltip: 'Удалить круг',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // УПРАЖНЕНИЯ В КРУГЕ
            ...exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;

              // НАХОДИМ ОРИГИНАЛЬНЫЙ ИНДЕКС УПРАЖНЕНИЯ В ОБЩЕМ СПИСКЕ
              final originalIndex = _template.exercises.indexWhere(
                  (e) => e.id == exercise.id
              );

              return _buildExerciseCard(exercise, originalIndex, true);
            }),
          ],
        ),
      ),
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
                    backgroundColor: Theme.of(context).colorScheme.error,
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
          backgroundColor: Theme.of(context).colorScheme.error,
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

  // ВКЛЮЧИТЬ/ВЫКЛЮЧИТЬ РЕЖИМ ВЫБОРА УПРАЖНЕНИЙ
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedExerciseIndices.clear();
      }
    });
  }

  // ВЫБРАТЬ/СНЯТЬ ВЫБОР С УПРАЖНЕНИЯ
  void _toggleExerciseSelection(int index){
    setState(() {
      if (_selectedExerciseIndices.contains(index)){
        _selectedExerciseIndices.remove(index);
      } else {
        _selectedExerciseIndices.add(index);
      }
    });
  }

  // СОЗДАТЬ НОВЫЙ КРУГ ИЗ ВЫБРАННЫХ УПРАЖНЕНИЙ
  void _createCircleFromSelected() {
    if (_selectedExerciseIndices.length < 2){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Выберите минимум 2 упражнения для создания круга'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // СОРТИРУЕМ ИНДЕКСЫ ПО ВОЗРАСТАНИЮ
    _selectedExerciseIndices.sort();

    // СОЗДАЕМ НОВЫЙ КРУГ
    setState(() {
      _template = _template.copyWith(
        exercises: CircleUtils.createNewCircle(
          _template.exercises,
          _selectedExerciseIndices,
        ),
      );

      // СБРАСЫВАЕМ РЕЖИМ ВЫБОРА
      _isSelectionMode = false;
      _selectedExerciseIndices.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Создан круг с ${_selectedExerciseIndices.length} упражнений'),
        backgroundColor: Color(0xFF81C784),
      ),
    );
  }

  // УДАЛИТЬ КРУГ
  void _removeCircle(int circleNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить круг?'),
        content: Text('Вы уверены, что хотите удалить круг №$circleNumber?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  _template = _template.copyWith(
                    exercises: CircleUtils.removeCircle(
                        _template.exercises,
                        circleNumber,
                    ),
                  );
                });
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
}