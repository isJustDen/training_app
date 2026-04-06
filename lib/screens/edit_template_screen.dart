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
  bool _isCustomDay = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState(){
    super.initState();
    // Создаем копию шаблона для редактирования
    // (чтобы не менять оригинал до сохранения)
    _template = widget.template.copyWith();

    // Заполняем контроллеры текущими значениями
    _nameController.text = _template.name;
    _dayController.text = _template.dayOfWeek;

    _isCustomDay = _template.dayOfWeek.isNotEmpty &&
      !_dayOptions
        .where((o) => o['value'] != '__custom__')
        .map((o) => o['value'] as String)
        .contains(_template.dayOfWeek);

    _hasUnsavedChanges = false;
  }

  @override
  Widget build(BuildContext context){
    return WillPopScope (
      onWillPop: _onWillPop,
      child: Scaffold(
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
      ),
    );

  }

  @override
  void didUpdateWidget (covariant EditTemplateScreen oldWidget){
    super.didUpdateWidget(oldWidget);
    if (widget.template != oldWidget.template) {
      setState(() {
        _template = widget.template.copyWith();
        _nameController.text = _template.name;
        _dayController.text = _template.dayOfWeek;
        _hasUnsavedChanges = false;
      });
    }
  }

// МЕТОД ДЛЯ ПОСТРОЕНИЯ ОСНОВНОГО СОДЕРЖИМОГО
  Widget _buildBody(){
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 80.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ЗАГОЛОВОК И ОПИСАНИЕ
          _buildHeader(),
          const SizedBox(height: 24),
          _buildEditFields(),
          const SizedBox(height: 24),
          // ПОЛЯ ДЛЯ РЕДАКТИРОВАНИЯ
          _buildDaySelector(),
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
            _markUnsavedChanges();
          }
        ),
        const SizedBox(height: 16),
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
        _buildReorderableExercises(),
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
            if (exercise.isTimeBased)
              Row(
                children: [
                  Icon(Icons.timer_rounded, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                      '${exercise.sets} подх. по ${exercise.targetSeconds} сек',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              )
            else
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
            // ХЭНДЛ ДЛЯ ПЕРЕТАСКИВАНИЯ
            if (!_isSelectionMode && !exercise.isInAnyCircle)
              ReorderableDelayedDragStartListener(
                  child: const Icon(Icons.drag_handle, color: Colors.grey),
                  index: _template.exercises
                    .where((e) => !e.isInAnyCircle)
                    .toList()
                    .indexWhere((e) => e.id == exercise.id),
              ),

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

    _markUnsavedChanges();

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
              _markUnsavedChanges();
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

  Widget _buildReorderableExercises(){
    final freeExercises = _template.exercises
        .asMap()
        .entries
        .where((entry) => !entry.value.isInAnyCircle)
        .toList();

    if (freeExercises.isEmpty) return const SizedBox.shrink();

    return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, i){
          final originalIndex = freeExercises[i].key;
          final exercise = freeExercises[i].value;
          return KeyedSubtree(
              key: ValueKey(exercise.id),
              child: _buildExerciseCard(exercise, originalIndex, false),
          );
        },
        itemCount: freeExercises.length,
        onReorder:(oldIndex, newIndex){
          // Flutter передаёт индексы ВНУТРИ ReorderableListView (0, 1, 2...)
          setState(() {
            if(newIndex > oldIndex) newIndex --;
            // Получаем оригинальные индексы
            final fromOriginal = freeExercises[oldIndex].key;
            final toOriginal = freeExercises[newIndex].key;
            // Переставляем в основном списке
            final exercises = List<Exercise>.from(_template.exercises);
            final item = exercises.removeAt(fromOriginal);
            exercises.insert(toOriginal, item);

            _template = _template.copyWith(exercises: exercises);
          });
          _markUnsavedChanges();
        },

      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) {
        // proxyDecorator — внешний вид карточки ПОКА её тянут
        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: child,
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
                  _markUnsavedChanges();
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

    _hasUnsavedChanges = false;
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

    // СОХРАНЯЕМ КОЛИЧЕСТВО ДО ОЧИСТКИ
    final count = _selectedExerciseIndices.length;

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

    _markUnsavedChanges();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Создан круг с ${count} упражнений(ия)'),
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
                _markUnsavedChanges();
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

  static const List<Map<String, dynamic>> _dayOptions = [
    {'label' : 'Понедельник',     'icon': '1️⃣',    'value': 'Понедельник'},
    {'label' : 'Вторник',         'icon': '2️⃣',    'value': 'Вторник'},
    {'label' : 'Среда',           'icon': '3️⃣',    'value': 'Среда'},
    {'label' : 'Четверг',         'icon': '4️⃣',    'value': 'Четверг'},
    {'label' : 'Пятница',         'icon': '5️⃣',    'value': 'Пятница'},
    {'label' : 'Суббота',         'icon': '6️⃣',    'value': 'Суббота'},
    {'label' : 'Воскресенье',     'icon': '7️⃣',    'value': 'Воскресенье'},
    {'label' : 'Каждый день',     'icon': '🏋️',    'value': 'Каждый день'},
    {'label' : 'По будням',       'icon': '📅',    'value': 'По будням'},
    {'label' : 'Через день',      'icon': '🔄',    'value': 'Через день'},
    {'label' : 'Свой вариант',    'icon': '✏️',    'value': '__custom__'},
  ];

  Widget _buildDaySelector(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showDayPicker,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'День недели / расписание',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            child: Text(
                _isCustomDay
                    ? (_template.dayOfWeek.isEmpty ? 'Свой вариант...' : _template.dayOfWeek)
                    :(_template.dayOfWeek.isEmpty ? 'Выберите...' : _template.dayOfWeek),
              style: TextStyle(
                fontSize: 16,
                color: _template.dayOfWeek.isEmpty
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // ПОЛЕ СВОЕГО ВАРИАНТА — показывается только если выбран custom
        if (_isCustomDay ) ... [
          const SizedBox(height: 12),
          TextField(
            controller: _dayController,
            autofocus: true, // сразу открывает клавиатуру
            decoration: const InputDecoration(
              labelText: 'Ваш вариант',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
              hintText: 'Например пн/ср/пт',
            ),
            onChanged: (value){
              setState(() {
                _template = _template.copyWith(dayOfWeek: value);
              });
            },
          ),
        ]
      ],
    );
  }

  void _showDayPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // ХЭНДЛ
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Выберите расписание',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const Divider(height: 1),

                // СПИСОК ВАРИАНТОВ
                Expanded(
                    child:ListView(
                      controller: scrollController,
                      children: [
                        ...(_dayOptions.map((option) {
                          final value = option['value'] as String;
                          final isSelected = value != '__custom__' &&
                              _template.dayOfWeek == value;

                          return Column(
                            children: [
                              if (value == '__custom__')
                                Divider(
                                  height: 1,
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                                ),
                              ListTile(
                                leading: Text(
                                  option['icon'] as String,
                                  style:  const TextStyle(fontSize: 20),
                                ),
                                title: Text(option['label'] as String),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary)
                                    : null,
                                onTap: (){
                                  Navigator.pop(context);
                                  if(value == '__custom__'){
                                    // Очищаем и показываем поле ввода
                                    setState(() {
                                      _isCustomDay = true;
                                      _dayController.text = '';
                                      _template = _template.copyWith(dayOfWeek: '');
                                    });
                                    _markUnsavedChanges();
                                  } else {
                                    setState(() {
                                      _isCustomDay = false;
                                      _template = _template.copyWith(dayOfWeek: value);
                                      _dayController.text = value;
                                    });
                                    _markUnsavedChanges();
                                  }
                                },
                              ),
                            ],
                          );
                        })),
                        const SizedBox(height: 16),
                      ],
                    ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //МЕТОД ДЛЯ ОТМЕТКИ ИЗМЕНЕНИЙ
  void _markUnsavedChanges () {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  //МЕТОД ДЛЯ ОБРАБОТКИ НАЗАД
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldPop = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Несохраненные изменения'),
          content: const Text('У вас есть несохраненные изменения. Выйти без сохранения?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text("Выйти"),
            ),
          ],
        ),
      );
      return shouldPop ?? false;
    }
    return true;
  }
}