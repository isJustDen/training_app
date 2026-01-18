//screens/workout_screen.dart

import 'package:flutter/material.dart';
import '../models/workout_template.dart';
import '../models/workout_progress.dart';
import '../widgets/timer_widget.dart';
import '../services/storage_service.dart';
import '../models/workout_history.dart';
import '../models/exercise.dart';


// ЭКРАН АКТИВНОЙ ТРЕНИРОВКИ
// StatefulWidget потому что состояние постоянно меняется
class WorkoutScreen extends StatefulWidget{
  final WorkoutTemplate template;

  const WorkoutScreen({
   super.key,
   required this.template,
});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>{
  // СПИСОК ДЛЯ ОТСЛЕЖИВАНИЯ ПРОГРЕССА КАЖДОГО УПРАЖНЕНИЯ
  late List<ExerciseProgress> _exercisesProgress;

  // ТАЙМЕР ОТДЫХА
  int _restTimeRemaining = 0;
  bool _isResting = false;

  // ИНДЕКС ТЕКУЩЕГО УПРАЖНЕНИЯ
  int _currentExerciseIndex = 0;

  // ВРЕМЯ НАЧАЛА ТРЕНИРОВКИ
  late DateTime _workoutStartTime;

  // initState() - ВЫЗЫВАЕТСЯ ПРИ СОЗДАНИИ ВИДЖЕТА
  @override
  void initState(){
    super.initState();
    _initializeWorkout();
  }

  // ИНИЦИАЛИЗАЦИЯ ТРЕНИРОВКИ
  void _initializeWorkout(){
    // Запоминаем время начала
    _workoutStartTime = DateTime.now();

    // СОЗДАЕМ ПРОГРЕСС ДЛЯ КАЖДОГО УПРАЖНЕНИЯ
    _exercisesProgress = widget.template.exercises.map((exercise){
      return ExerciseProgress(
          exercise: exercise,
          currentWeight: exercise.weight
      );
    }).toList();

    print('Тренировка начата: ${widget.template.name}');
  }

  @override

  Widget build(BuildContext context){
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ВЕРХНЯЯ ПАНЕЛЬ (AppBar)
  AppBar _buildAppBar(){
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.template.name,
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            '${_currentExerciseIndex + 1}/${_exercisesProgress.length} упражнений',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        // КНОПКА ЗАВЕРШЕНИЯ ТРЕНИРОВКИ
        IconButton(
            onPressed: _finishWorkout,
            icon: const Icon(Icons.done_all),
            tooltip: 'Завершить тренировку',
        ),
      ],
    );
  }

  // ОСНОВНОЕ СОДЕРЖИМОЕ ЭКРАНА
  Widget _buildBody(){
    return Column(
      children: [
        // ТАЙМЕР ОТДЫХА (если активен)
        if (_isResting)
          TimerWidget(
            initialTime: _restTimeRemaining,
            onComplete: _endRestPeriod,
            onSkip: _endRestPeriod,
          ),

        // ТАБЛИЦА УПРАЖНЕНИЙ
        Expanded(
            child: _buildExercisesTable(),
        ),
      ],
    );
  }

  // ТАБЛИЦА УПРАЖНЕНИЙ С ИСПОЛЬЗОВАНИЕМ ListView.
  Widget _buildExercisesTable(){
    return ListView.builder(
      itemCount: _exercisesProgress.length,
      itemBuilder: (context, index){
        final progress = _exercisesProgress[index];
        final exercise = progress.exercise;
        final isCurrent = index == _currentExerciseIndex;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCurrent ? Colors.blue.withOpacity(0.1): Colors.white,
            border: Border.all(
              color: isCurrent ? Colors.blue: Colors.grey.shade300,
              width: isCurrent ? 2:1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // ЗАГОЛОВОК СТРОКИ - НОМЕР И НАЗВАНИЕ
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.blue: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index+1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // НАЗВАНИЕ УПРАЖНЕНИЯ
                    Expanded(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ПАРАМЕТРЫ УПРАЖНЕНИЯ В 2 СТРОКИ
                // СТРОКА 1: ВЕС, ПОДХОДЫ, ПОВТОРЕНИЯ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [

                    // ВЕС
                    _buildParameterCard(
                      title: 'Вес',
                      value: '${progress.currentWeight.toStringAsFixed(1)} кг',
                      icon: Icons.fitness_center,
                      onEdit: () => _showWeightEditor(index),
                    ),

                    // ПОДХОДЫ
                    _buildParameterCard(
                      title: 'Подходы',
                      value: '${progress.completedSets}/${exercise.sets}',
                      icon: Icons.repeat,
                      color: progress.isCompleted ? Colors.green: null,
                    ),

                    // ПОВТОРЕНИЯ
                    _buildParameterCard(
                      title: 'Повторения',
                      value: '${progress.completedReps}',
                      icon: Icons.repeat_one,
                      onIncrement: () => _incrementReps(index),
                      onDecrement: () => _decrementReps(index),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // СТРОКА 2: ПРОГРЕСС И ДЕЙСТВИЯ
                Row(
                  children: [
                    // ПРОГРЕСС-БАР
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: progress.progressPercentage / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress.isCompleted ? Colors.green : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${progress.progressPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, color:Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // КНОПКИ ДЕЙСТВИЙ
                    Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // КНОПКА ЗАВЕРШЕНИЯ ПОДХОДА
                            IconButton(
                                onPressed: progress.isCompleted
                                    ? null
                                    : () => _completeSet(index),
                                icon: Icon(
                                  Icons.check_circle,
                                  color: progress.isCompleted ? Colors.grey: Colors.green,
                                ),
                                tooltip: 'Завершить подход',
                            ),

                            // КНОПКА ТАЙМЕРА
                            IconButton(
                              icon: const Icon(Icons.timer, color: Colors.orange),
                              onPressed: () => _startRestTimer(index),
                              tooltip: 'Таймер',
                            ),
                          ],
                        ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ СОЗДАНИЯ КАРТОЧКИ ПАРАМЕТРА
  Widget _buildParameterCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
    VoidCallback? onEdit,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    return Expanded(
        child: GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: color ?? Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: color ?? Colors.grey.shade700,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                if (onIncrement != null && onDecrement != null)
                // ДЛЯ ПОВТОРЕНИЙ - ДВЕ КНОПКИ (+ и -) ПО БОКАМ ОТ ЗНАЧЕНИЯ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    GestureDetector(
                      onTap: onDecrement,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 20,
                          color: Colors.red,
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      Container(
                        constraints: BoxConstraints(minWidth: 40),
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color ?? Colors.black,
                          ),
                        ),
                      ),

                      const SizedBox(width: 4),

                      GestureDetector(
                        onTap: onIncrement,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                // ДЛЯ ОСТАЛЬНЫХ ПАРАМЕТРОВ - ПРОСТО ТЕКСТ
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  // НИЖНЯЯ ПАНЕЛЬ (BottomAppBar)
  Widget _buildBottomBar(){
    return BottomAppBar(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // КНОПКА ПРЕДЫДУЩЕГО УПРАЖНЕНИЯ
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 15),
              label:  const Text('Назад'),
              onPressed: _currentExerciseIndex > 0
                  ? _previousExercise
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 40),
              ),
            ),

            // ИНФОРМАЦИЯ О ТЕКУЩЕМ УПРАЖНЕНИИ
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Упражнение ${_currentExerciseIndex+1}',
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
                Text(
                  '${_exercisesProgress[_currentExerciseIndex].exercise.name}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_exercisesProgress[_currentExerciseIndex].remainingSets} подходов осталось',
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // КНОПКА СЛЕДУЮЩЕГО УПРАЖНЕНИЯ
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward, size: 15),
              label: const Text('Вперёд'),
              onPressed: _currentExerciseIndex < _exercisesProgress.length - 1
                ? _nextExercise
                : null,
              style: ElevatedButton.styleFrom(
               minimumSize: const Size(100, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

// ========== МЕТОДЫ ДЛЯ РАБОТЫ С ДАННЫМИ ==========

  // ОБНОВЛЕНИЕ ВЕСА УПРАЖНЕНИЯ
  void _updateWeight(int index, String value){
    final weight = double.tryParse(value) ?? 0.0;

    setState(() {
      _exercisesProgress[index] = _exercisesProgress[index].copyWith(
        currentWeight: weight,
      );
    });
  }

  // ПЕРЕГРУЗКА МЕТОДА ДЛЯ ПРИНЯТИЯ double
  void _updateWeightDirect(int index, double weight){
    setState(() {
      _exercisesProgress[index] = _exercisesProgress[index].copyWith(
        currentWeight: weight,
      );
    });
  }

  // УВЕЛИЧЕНИЕ КОЛИЧЕСТВА ПОВТОРЕНИЙ НА 1
  void _incrementReps(int index){
    setState(() {
      final currentReps = _exercisesProgress[index].completedReps;
      _exercisesProgress[index] = _exercisesProgress[index].copyWith(
        completedReps: currentReps + 1,
      );
    });
  }

  // УМЕНЬШЕНИЕ КОЛИЧЕСТВА ПОВТОРЕНИЙ НА 1
  void _decrementReps(int index) {
    if (_exercisesProgress[index].completedReps > 0) {
      setState(() {
        final currentReps = _exercisesProgress[index].completedReps;
        _exercisesProgress[index] = _exercisesProgress[index].copyWith(
          completedReps: currentReps - 1,
        );
      });
    }
  }

  // ЗАВЕРШЕНИЕ ПОДХОДА
  void _completeSet(int index) {
    setState(() {
      final currentSets = _exercisesProgress[index].completedSets;
      _exercisesProgress[index] = _exercisesProgress[index].copyWith(
        completedSets: currentSets + 1,
        completedReps: 0, // Сбрасываем повторения для нового подхода
      );
    });
    // предложение отдыха после завершения подхода
    _showRestPrompt(index);
  }

  // ПОКАЗАТЬ ПРЕДЛОЖЕНИЕ ОБ ОТДЫХЕ
  void _showRestPrompt(int index){
    final exercise = _exercisesProgress[index].exercise;

    // ЕСЛИ ЕЩЕ ЕСТЬ НЕВЫПОЛНЕННЫЕ ПОДХОДЫ
    if (_exercisesProgress[index].remainingSets > 0){
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Отдых'),
          content: Text(
              'Выполнен подход ${_exercisesProgress[index].completedSets}/${exercise.sets}\n'
                  'Хотите запустить таймер отдыха?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Пропустить'),
            ),
            ElevatedButton(
              onPressed: (){
                Navigator.pop(context);
                _startRestTimer(index);
              },
              child: const Text('Запустить таймер'),
            ),
          ],
        ),
      );
    }
  }

  // ЗАПУСК ТАЙМЕРА ОТДЫХА
  void _startRestTimer(int index){
    final exercise = _exercisesProgress[index].exercise;

    // ПОКАЗЫВАЕМ ДИАЛОГ ДЛЯ ВЫБОРА ВРЕМЕНИ
    showDialog(
      context: context,
      builder: (context) {

        int selectedTime = exercise.restTime ~/ 60;

        return StatefulBuilder(
          builder: (context, setState){
            return AlertDialog(
              title: const Text('Таймер отдыха'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Выберите время отдыха'),
                  const SizedBox(height: 16),

                  // ВЫБОР ВРЕМЕНИ С ПОМОЩЬЮ SLIDER
                  Slider(
                    value: selectedTime.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 18,
                    label:'$selectedTime мин',
                    onChanged: (value){
                      setState(() {
                        selectedTime = value.round();
                        });
                    },
                  ),

                  Text(
                    '$selectedTime минут',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                ),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startTimer(selectedTime * 60);
                    },
                    child: const Text('Запустить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

 // ЗАПУСК ТАЙМЕРА

  void _startTimer(int seconds){
    setState(() {
      _restTimeRemaining = seconds;
      _isResting = true;
    });
  }

  // ЗАВЕРШЕНИЕ ОТДЫХА
  void _endRestPeriod(){
    setState(() {
      _isResting = false;
      _restTimeRemaining = 0;
    });
  }

  // ПЕРЕХОД К ПРЕДЫДУЩЕМУ УПРАЖНЕНИЮ
  void _previousExercise(){
    if (_currentExerciseIndex > 0){
      setState(() {
        _currentExerciseIndex--;
      });
    }
  }

  // ПЕРЕХОД К СЛЕДУЮЩЕМУ УПРАЖНЕНИЮ
  void _nextExercise(){
    if (_currentExerciseIndex < _exercisesProgress.length -1){
      setState(() {
        _currentExerciseIndex++;
      });
    }
  }

  // ЗАВЕРШЕНИЕ ТРЕНИРОВКИ
  void _finishWorkout(){
    final duration = DateTime.now().difference(_workoutStartTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final formattedSeconds = seconds.toString().padLeft(2, '0');

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Завершить тренировку?'),
          content: Text('Продолжительность: ${minutes}: ${seconds.toString().padLeft(2, '0')}\n'
                        'Хотите завершить тренировку?'
          ),
          actions: [
            TextButton(
              onPressed : () => Navigator.pop(context),
              child: const Text('Продолжить'),
            ),
            ElevatedButton(
              onPressed: () async {
                // СОЗДАЕМ ЗАПИСЬ В ИСТОРИИ
                final workoutHistory = WorkoutHistory(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  templateId: widget.template.id,
                  date: DateTime.now(),
                  exercises: _exercisesProgress
                      .map((progress) => Exercise(
                      id: progress.exercise.id,
                      name: progress.exercise.name,
                      weight: progress.currentWeight,
                      sets: progress.completedSets,
                      reps: progress.completedReps,
                      restTime: progress.exercise.restTime,
                      ))
                      .toList(),
                  duration: duration.inSeconds,
                );

                // СОХРАНЯЕМ В ИСТОРИЮ
                await StorageService.addToHistory(workoutHistory);

                print('Тренировка сохранена в историю!');
                Navigator.pop(context); //Закрыть диалог

                // ПОКАЗЫВАЕМ УВЕДОМЛЕНИЕ О СОХРАНЕНИИ
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Тренировка сохранена в историю'),
                    backgroundColor: Colors.green,
                  ),
                );

                // ЗАДЕРЖКА ДЛЯ ПОКАЗА SNACKBAR
                await Future.delayed(const Duration(milliseconds: 1500));

                Navigator.pop(context); // вернуться к списку тренировок
              },
              child: const Text('Завершить и сохранить'),
            ),
          ],
        ),
    );
  }

  // РЕДАКТИРОВАНИЕ ВЕСА ЧЕРЕЗ ДИАЛОГ
  void _showWeightEditor(int index){
    final progress = _exercisesProgress[index];
    final controller = TextEditingController(
      text: progress.currentWeight.toStringAsFixed(1),
    );

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Вес (кг)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
            ),
            ElevatedButton(
                onPressed: () {
                  final weight = double.tryParse(controller.text) ?? 0.0;
                  _updateWeight(index, weight.toString());
                  Navigator.pop(context);
                },
                child: const Text('Сохранить'),
            ),
          ],
        ),
    );
  }


}
