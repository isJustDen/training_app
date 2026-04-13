//screens/workout_screen.dart

import 'package:fitflow/models/workout_circle.dart';
import 'package:fitflow/models/workout_session.dart';
import 'package:fitflow/providers/settings_provider.dart';
import 'package:fitflow/screens/workout_complete_screen.dart';
import 'package:fitflow/utils/circle_utils.dart';
import 'package:fitflow/widgets/stopwatch_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/workout_template.dart';
import '../models/workout_progress.dart';
import '../services/notification_service.dart';
import '../widgets/timer_widget.dart';
import '../services/storage_service.dart';
import '../models/workout_history.dart';
import '../models/exercise.dart';
import '../services/history_service.dart';
import '../services/sound_service.dart';
import 'dart:async';


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

  // ДОПОЛНИТЕЛЬНЫЕ ПОЛЯ Последние результаты и Средние показатели:
  late Map<String, Exercise?> _lastExerciseResults;
  late Map <String, Map<String, dynamic>> _averageStats;
  final  ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _exerciseKeys = [];

  // ТАЙМЕР ОТДЫХА
  int _restTimeRemaining = 0;
  bool _isResting = false;

  // ИНДЕКС ТЕКУЩЕГО УПРАЖНЕНИЯ
  int _currentExerciseIndex = 0;

  // ВРЕМЯ НАЧАЛА ТРЕНИРОВКИ
  late DateTime _workoutStartTime;
  List<WorkoutCircle> _workoutCircles = []; // Список кругов
  int _currentCircleIndex = 0; // Текущий круг
// Текущее упражнение в круге
  bool _isInCircleMode = false; // Режим выполнения круга

  Timer? _clockTimer;

  Timer ? _dimTimer;
  bool _isDimmed = false;

  int _dimAfterSeconds = 15;
  bool _dimEnabled = true;

  // initState() - ВЫЗЫВАЕТСЯ ПРИ СОЗДАНИИ ВИДЖЕТА
  @override
  void initState(){
    super.initState();
    _initializeWorkout();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_){
      if(mounted) setState(() {});
    });
  }

  // ИНИЦИАЛИЗАЦИЯ ТРЕНИРОВКИ
  void _initializeWorkout() async{
    // Запоминаем время начала
    _workoutStartTime = DateTime.now();

    // СОЗДАЕМ ПРОГРЕСС ДЛЯ КАЖДОГО УПРАЖНЕНИЯ
    _exercisesProgress = widget.template.exercises.map((exercise){
      return ExerciseProgress(
        exercise: exercise,
        currentWeight: exercise.weight,
        currentReps: 0,
      );
    }).toList();
    _exerciseKeys.clear();
    for (int i = 0; i < _exercisesProgress.length; i++) {
      _exerciseKeys.add(GlobalKey());
    }

    // СОЗДАЕМ КРУГИ ИЗ УПРАЖНЕНИЙ
    _createWorkoutCircles();

    // ЗАГРУЖАЕМ ИСТОРИЧЕСКИЕ ДАННЫЕ ДЛЯ КАЖДОГО УПРАЖНЕНИЯ
    await _loadExerciseHistory();

    // ПРОВЕРЯЕМ — есть ли сохранённая сессия для этого шаблона
    final savedSession = await StorageService.loadWorkoutSession(widget.template.id );

    if (savedSession != null && savedSession.hasProgress && mounted) {
      _showRestoreSessionDialog(savedSession);
    }
  }

  @override
  void dispose(){
    _clockTimer?.cancel();
    _dimTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false).settings;
    _dimEnabled = settings.dimScreenEnabled;
    _dimAfterSeconds = settings.dimAfterSeconds;
    _resetDimTimer();
  }

  //МЕТОД ДЛЯ ЗАГРУЗКИ ИСТОРИИ
  Future<void> _loadExerciseHistory() async{
    _lastExerciseResults = {};
    _averageStats = {};

    for(var progress in _exercisesProgress){
      final exerciseName = progress.exercise.name;

      // ПОЛУЧАЕМ ПОСЛЕДНИЙ РЕЗУЛЬТАТ
      final lastResult = await HistoryService.getLastExerciseResult(exerciseName);
      if (lastResult != null) {
        _lastExerciseResults[exerciseName] = lastResult;
      }

      // ПОЛУЧАЕМ СРЕДНИЕ ПОКАЗАТЕЛИ
      final averageStats = await HistoryService.getAverageExerciseStats(
          exerciseName,
          3
      );
      _averageStats[exerciseName] = averageStats;
    }
  }

  @override
  Widget build(BuildContext context){
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        onTap: _resetDimTimer,
        onPanDown: (_) => _resetDimTimer(),// ловим и свайпы тоже
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Scaffold(
            appBar: _buildAppBar(),
            body: _buildBody(),
            bottomNavigationBar: _buildBottomBar(),
              ),
            // ЗАТЕМНЯЮЩИЙ СЛОЙ
            if(_isDimmed)
              GestureDetector(
                onTap: _resetDimTimer,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    color: Colors.black.withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: Colors.white.withOpacity(0.3),
                            size: 100,
                          ),
                          const SizedBox(height: 50,),
                          Text(
                            'Коснитесь для продолжения',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ВЕРХНЯЯ ПАНЕЛЬ (AppBar)
  AppBar _buildAppBar() {
    final circleInfo = _isInCircleMode && _workoutCircles.isNotEmpty
        ? ' | Круг ${_currentCircleIndex + 1}/${_workoutCircles.length}'
        : '';
    final exerciseInfo = _exercisesProgress.isEmpty
        ? 'Нет упражнений'
        : '${_currentExerciseIndex+1}/${_exercisesProgress.length} упражнений';

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.template.name}$circleInfo',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            exerciseInfo,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
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
        // ПРОГРЕСС ТРЕНИРОВКИ
        _buildWorkoutProgressBar(),

        // ТАЙМЕР ОТДЫХА (если активен)
        if (_isResting)
          TimerWidget(
            initialTime: _restTimeRemaining,
            onComplete: _endRestPeriod,
            onSkip: _endRestPeriod,
            // ДОБАВЛЯЕМ НАЗВАНИЕ УПРАЖНЕНИЯ ДЛЯ УВЕДОМЛЕНИЯ
            exerciseName: _exercisesProgress.isNotEmpty
                ?_exercisesProgress[_currentExerciseIndex].exercise.name
                : "Упражнение",
          ),

        // ТАБЛИЦА УПРАЖНЕНИЙ
        Expanded(
          child:  _exercisesProgress.isEmpty
              ? _buildEmptyWorkout()
              : _buildExercisesTable(),
        ),
      ],
    );
  }

  // НОВЫЙ ВИДЖЕТ — пустая тренировка
  Widget _buildEmptyWorkout(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),

          const SizedBox(height: 16),

          Text(
            'В этой тренировке нет упражнений',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Вернуться назад'),
          ),
        ],
      ),
    );
  }

  // ТАБЛИЦА УПРАЖНЕНИЙ С ИСПОЛЬЗОВАНИЕМ ListView.
  Widget _buildExercisesTable(){
    return ListView.builder(
      controller: _scrollController,
      itemCount: _exercisesProgress.length,
      itemBuilder: (context, index){
        final progress = _exercisesProgress[index];
        final exercise = progress.exercise;
        final isCurrent = index == _currentExerciseIndex;
        final exerciseName = exercise.name;

        // ПОЛУЧАЕМ ИСТОРИЧЕСКИЕ ДАННЫЕ ДЛЯ ЭТОГО УПРАЖНЕНИЯ
        final lastResult = _lastExerciseResults[exerciseName];

        // ОПРЕДЕЛЯЕМ, ПРИНАДЛЕЖИТ ЛИ УПРАЖНЕНИЕ КРУГУ
        final isInCircle = exercise.isInAnyCircle;
        final circleNumber = exercise.circleNumber;
        final circleColor = isInCircle
            ? CircleUtils.getCircleColor(circleNumber)
            : null;

        // ОПРЕДЕЛЯЕМ, ЯВЛЯЕТСЯ ЛИ ЭТО ТЕКУЩИМ КРУГОМ

        final currentExercise = _exercisesProgress.isNotEmpty
            ? _exercisesProgress[_currentExerciseIndex].exercise
            : null;

        // Круг "текущий" если в нём находится текущее упражнение
        final isCurrentCircle = isInCircle &&
            currentExercise != null &&
            currentExercise.isInAnyCircle &&
            currentExercise.circleNumber == circleNumber;

        return GestureDetector(
          onTap: () {
            setState(() => _currentExerciseIndex = index);
            _scrollToCurrentExercise(index);
          },
          child: Stack(
            key: _exerciseKeys[index],
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getExerciseBackgroundColor(isCurrent, isInCircle, isCurrentCircle, circleColor, progress.isCompleted),
                  border: Border.all(
                    color: _getExerciseBorderColor(isCurrent, isInCircle, isCurrentCircle, circleColor, progress.isCompleted),
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
                          _buildExerciseNumberIndicator(index, exercise, isCurrent, circleColor),
                          const SizedBox(width: 12,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: progress.isCompleted
                                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                        : null,
                                  ),
                                ),
                                if (isInCircle)
                                  Row(
                                    children: [
                                      Icon(
                                        CircleUtils.getCircleIcon(circleNumber),
                                        size: 12,
                                        color: circleColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Круг $circleNumber (${exercise.circleOrder})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: circleColor,
                                        ),
                                      ),
                                    ],
                                  ),

                                // ИСТОРИЧЕСКИЕ ДАННЫЕ (ЕСЛИ ЕСТЬ)
                                if (lastResult != null && !exercise.isTimeBased)
                                  _buildHistoryIndicator(exercise, lastResult),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ПАРАМЕТРЫ УПРАЖНЕНИЯ В 2 СТРОКИ
                      // СТРОКА 1: ВЕС, ПОДХОДЫ, ПОВТОРЕНИЯ
                      if (!exercise.isTimeBased) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [

                            // ВЕС
                            _buildParameterCard(
                              title: 'Вес',
                              value: '${progress.currentWeight.toStringAsFixed(1)} кг',
                              icon: Icons.fitness_center,
                              onEdit: progress.isCompleted ? null : () => _showWeightEditor(index),
                              color: progress.isCompleted ? Colors.green : Theme.of(context).colorScheme.onSurface,
                            ),

                            // ПОДХОДЫ
                            _buildParameterCard(
                              title: 'Подходы',
                              value: '${progress.completedSetsCount}/${exercise.sets}',
                              icon: Icons.repeat,
                              color: progress.isCompleted ? Colors.green: Theme.of(context).colorScheme.onSurface,
                            ),

                            // ПОВТОРЕНИЯ
                            _buildParameterCard(
                              title: 'Повторения',
                              value: '${progress.currentReps}',
                              icon: Icons.repeat_one,
                              onIncrement: progress.isCompleted ? null : () => _incrementReps(index),
                              onDecrement: progress.isCompleted ? null : () => _decrementReps(index),
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (exercise.isTimeBased) ... [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.repeat, size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Подходы: ${progress.completedSetsCount}/ ${exercise.sets}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // СТРОКА 2: ПРОГРЕСС И ДЕЙСТВИЯ
                      if (exercise.isTimeBased && !progress.isCompleted)
                        StopwatchWidget(
                          targetSeconds: exercise.targetSeconds,
                          onStopped: (elapsedSeconds) {
                            _completeTimeBasedSet(index, elapsedSeconds);
                          },
                        ) else
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
                                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      progress.isCompleted ? Colors.green : Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${progress.progressPercentage.toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 12, color:Colors.white),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // КНОПКИ ДЕЙСТВИЙ
                            if (!progress.isCompleted) ... [
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (progress.completedSetsCount > 0)
                                      _buildDeleteSetButton(index, progress),
                                    const SizedBox(width: 10),
                                    if (_shouldShowTimer(exercise)) ...[
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
                                    ] else ...[
                                      IconButton(
                                        onPressed: progress.isCompleted
                                            ? null
                                            : () => _completeSet(index),
                                        icon: Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: progress.isCompleted ? Colors.grey : Colors.green,
                                        ),
                                        tooltip: 'Завершить подход',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              // БОЛЬШАЯ ПОЛУПРОЗРАЧНАЯ ГАЛОЧКА ПОВЕРХ ЗАВЕРШЁННОЙ КАРТОЧКИ
              if (progress.isCompleted)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_circle_outline_sharp,
                        size: 110,
                        color: Colors.green.withOpacity(0.4),
                      ),
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ ОПРЕДЕЛЕНИЯ ЦВЕТОВ:
  Color _getExerciseBackgroundColor(
      bool isCurrent,
      bool isInCircle,
      bool isCurrentCircle,
      Color? circleColor,
      bool isCompleted,
      ){
    if (isCompleted) {
      return Colors.green.withOpacity(0.08);
    }
    if (isCurrent){
      return Theme.of(context).colorScheme.primary.withOpacity(0.15);
    }
    if (isInCircle && isCurrentCircle) {
      return circleColor!.withOpacity(0.07);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getExerciseBorderColor(
      bool isCurrent,
      bool isInCircle,
      bool isCurrentCircle,
      Color? circleColor,
      bool isCompleted,
      ){
    if (isCompleted) return Colors.green.withOpacity(0.3);
    if (isCurrent){
      return Colors.blue;
    } else if (isInCircle && isCurrentCircle){
      return circleColor!.withOpacity(0.3);
    }else if (isInCircle){
      return circleColor!.withOpacity(0.2);
    }
    return Theme.of(context).colorScheme.outline;
  }

  // ВИДЖЕТ ДЛЯ НОМЕРА УПРАЖНЕНИЯ:
  Widget _buildExerciseNumberIndicator(
      int index,
      Exercise exercise,
      bool isCurrent,
      Color? circleColor,
      ){
    if (exercise.isInAnyCircle){
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isCurrent
              ? Colors.blue
              : circleColor!.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: isCurrent ? Colors.blue : circleColor!,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            exercise.circleOrder.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCurrent ? Colors.white : circleColor,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isCurrent? Colors.blue: Theme.of(context).colorScheme.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                        fontSize: 13,
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
                          color: Theme.of(context).colorScheme.error,
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
                          color: color ?? Theme.of(context).colorScheme.onSurface,
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
                          size: 25,
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
                    color: color ?? Theme.of(context).colorScheme.onSurface,
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
    final duration = DateTime.now().difference(_workoutStartTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    // ✅ GUARD — если список пуст, показываем заглушку
    if (_exercisesProgress.isEmpty){
      return BottomAppBar(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Text(
              'Нет упражнений, добавьте их в шаблоне.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
    }

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

            // ИНФОРМАЦИЯ О ВРЕМЕНИ
            Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 12,),
                Text( '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    letterSpacing: 1.0,
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

  //МЕТОД ДЛЯ ПОКАЗА ИСТОРИЧЕСКИХ ДАННЫХ
  Widget _buildHistoryIndicator(Exercise current, Exercise lastResult){
    final weightDiff = current.weight - lastResult.weight;
    final repsDiff = current.reps - lastResult.reps;
    final hasSetsData = lastResult.completedSets.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        // ИНФОРМАЦИЯ О ПРОШЛОЙ ТРЕНИРОВКЕ
        Row(
          children: [
            Icon(Icons.history, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              'Прошлый раз:',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
        const SizedBox(height: 4,),

        // ЕСЛИ ЕСТЬ ДАННЫЕ ПО ПОДХОДАМ — показываем каждый
        if (hasSetsData)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: lastResult.completedSets.asMap().entries.map((entry){
              final setIndex = entry.key;
              final set = entry.value;
              final reps = set['reps'] as int;
              final weight = (set['weight'] as num).toDouble();

              // СРАВНИВАЕМ С ТЕКУЩИМ ПЛАНОМ
              final plannedReps = current.reps;
              final isAbovePlan = reps >= plannedReps;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isAbovePlan
                      ? Colors.green.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isAbovePlan
                        ? Colors.green.withOpacity(0.4)
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  '${setIndex + 1}:  $reps×${weight.toStringAsFixed(1)} кг',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isAbovePlan
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          )

        // ЕСЛИ СТАРАЯ ЗАПИСЬ БЕЗ ПОДХОДОВ — показываем по-старому
        else
          Text('${lastResult.weight}кг×${lastResult.reps} повт. (итого) ',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 6,),

        // ИНДИКАТОР ИЗМЕНЕНИЙ
        if (weightDiff != 0 || repsDiff != 0)
          Row(
            children: [
              // ИЗМЕНЕНИЕ ВЕСА
              if (weightDiff > 0)
                _buildChangeIndicator('+${weightDiff.toStringAsFixed(1)}кг', Colors.green)
              else if (weightDiff < 0)
                _buildChangeIndicator('${weightDiff.toStringAsFixed(1)}кг', Theme.of(context).colorScheme.error),

              const SizedBox(width: 8),

            ],
          ),
      ],
    );
  }

  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ ИНДИКАТОРА ИЗМЕНЕНИЙ
  Widget _buildChangeIndicator(String text, Color color){
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ОПРЕДЕЛЯЕТ, НУЖНО ЛИ ПОКАЗЫВАТЬ ТАЙМЕР ДЛЯ ЭТОГО УПРАЖНЕНИЯ
  bool _shouldShowTimer(Exercise exercise) {
    if (!exercise.isInAnyCircle) return true; // Обычное упражнение — таймер всегда показываем

    // Упражнение в круге — показываем таймер только последнему
    final circleExercises = widget.template.exercises
      .where((e) => e.circleNumber == exercise.circleNumber)
      .toList()
    ..sort((a, b) => a.circleOrder.compareTo(b.circleOrder));

    // Последнее = максимальный circleOrder в этом круге
    return circleExercises.isNotEmpty &&
      circleExercises.last.id == exercise.id;
  }

  //СТАТУС БАР ВЫПОЛНЕННЫХ УПРАЖНЕНИЙ
  Widget _buildWorkoutProgressBar() {
    if (_exercisesProgress.isEmpty) return const SizedBox.shrink();

    // СЧИТАЕМ ПРОГРЕСС ПО ПОДХОДАМ (более гранулярно)
    final completedSets = _exercisesProgress.fold(0, (sum, p) => sum + p.completedSetsCount);
    final totalSets = _exercisesProgress.fold(0, (sum, p) => sum + p.exercise.sets);
    final setsPercent = totalSets > 0 ? completedSets / totalSets : 0.0;

    final percentLabel = '${(setsPercent * 100).toStringAsFixed(0)}%';

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(setsPercent == 1.0? Icons.check_circle : Icons.fitness_center,
          size: 14,
            color: setsPercent == 1.0
                ? Colors.green
                :Theme.of(context).colorScheme.onSurfaceVariant,
          ),

          const SizedBox(width: 8,),

          // ПРОГРЕСС БАР
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: setsPercent,
                minHeight: 6,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  setsPercent < 0.33
                      ? Colors.blue
                      : setsPercent < 0.66
                        ?Colors.orange
                        :setsPercent == 1.0
                          ?Colors.green
                          : Colors.deepOrange,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8,),

          // ПРОЦЕНТ
          SizedBox(
            width: 36,
            child: Text(
              percentLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: setsPercent == 1.0
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // СЧЁТЧИК ПОДХОДОВ
          Text('($completedSets/$totalSets)',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

// ========== МЕТОДЫ ДЛЯ РАБОТЫ С ДАННЫМИ ==========

  // ОБНОВЛЕНИЕ ВЕСА УПРАЖНЕНИЯ
  void _updateWeight(int index, String value){
    HapticFeedback.mediumImpact();
    final weight = double.tryParse(value) ?? 0.0;

    setState(() {
      _exercisesProgress[index] = _exercisesProgress[index].copyWith(
        currentWeight: weight,
      );
    });
  }

  // УВЕЛИЧЕНИЕ КОЛИЧЕСТВА ПОВТОРЕНИЙ НА 1
  void _incrementReps(int index){
    HapticFeedback.mediumImpact();
    setState(() {
      final currentReps = _exercisesProgress[index].currentReps;
      _exercisesProgress[index] = _exercisesProgress[index].copyWith(
        currentReps: currentReps + 1,
      );
    });
  }

  // УМЕНЬШЕНИЕ КОЛИЧЕСТВА ПОВТОРЕНИЙ НА 1
  void _decrementReps(int index) {
    HapticFeedback.mediumImpact();
    if (_exercisesProgress[index].currentReps > 0) {
      setState(() {
        final currentReps = _exercisesProgress[index].currentReps;
        _exercisesProgress[index] = _exercisesProgress[index].copyWith(
          currentReps: currentReps - 1,
        );
      });
    }
  }

  // ЗАВЕРШЕНИЕ ПОДХОДА
  Future <void> _completeSet(int index) async {
    final progress = _exercisesProgress[index];

    if (progress.currentReps == 0){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Укажите количество повторений для ${progress.exercise.name}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // Добавляем подход с фактическими повторениями
      progress.addCompletedSet(progress.currentReps, progress.currentWeight);
    });
    await _saveSession();

    // ПРОВЕРЯЕМ — это последний подход в круге?
    final exercise = progress.exercise;
    final isLastSet = progress.completedSetsCount >= exercise.sets;

    if (isLastSet && exercise.isInAnyCircle) {
      final allCircleExercisesCompleted = _exercisesProgress
          .where((p) => p.exercise.circleNumber == exercise.circleNumber)
          .every((p) => p.isCompleted);

      if (allCircleExercisesCompleted) {
        _showCircleRestTimer (exercise.circleNumber);
        return;
      }
    }
    // предложение отдыха после завершения подхода
    if (progress.remainingSets > 0) {
      _startRestTimer(index);
    }
  }

  // ПОКАЗАТЬ ПРЕДЛОЖЕНИЕ ОБ ОТДЫХЕ
  void _showCircleRestTimer (int circleNumber){
    int selectedTime = 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context){
        return StatefulBuilder(
            builder: (context, setState){
              final minutes = selectedTime ~/ 60;
              final seconds = selectedTime % 60;
              final label = minutes > 0
                  ? '$minutesм ${seconds > 0 ? "$seconds с": ""}'
                  : '$secondsс';

              return AlertDialog(
                title: Row(
                  children: [
                    Icon(
                        CircleUtils.getCircleIcon(circleNumber),
                            color: CircleUtils.getCircleColor(circleNumber),
                    ),
                    const SizedBox(width: 8,),
                    Text('Круг $circleNumber завершён'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Все упражнения круга выполнены. \nВремя отдыха:',
                    textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: CircleUtils.getCircleColor(circleNumber),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: selectedTime.toDouble(),
                      min: 10,
                      max: 300,
                      divisions: 29,
                      label:label,
                      activeColor: Colors.blue,
                      onChanged: (value){
                        setState(() {
                          selectedTime = (value/10).round()*10;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Пропустить'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CircleUtils.getCircleColor(circleNumber),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _startTimer(selectedTime);
                    },
                    child: const Text('Запустить'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // ЗАПУСК ТАЙМЕРА ОТДЫХА
  void _startRestTimer(int index){
    final exercise = _exercisesProgress[index].exercise;

    int selectedTime = exercise.restTime.clamp(10, 300); // Дефолт = restTime из упражнения, но минимум 10 секунд
    selectedTime = (selectedTime/10).round() * 10;  // Округляем до кратного 10

    // ПОКАЗЫВАЕМ ДИАЛОГ ДЛЯ ВЫБОРА ВРЕМЕНИ
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState){
            final minutes = selectedTime ~/ 60;
            final seconds = selectedTime % 60;
            final label = minutes > 0
                ? '$minutesмин : $secondsсек'
                : '$secondsсек';

            return AlertDialog(
              title: const Text('Таймер отдыха'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ВЫБОР ВРЕМЕНИ С ПОМОЩЬЮ SLIDER
                  Slider(
                    value: selectedTime.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    label:label,
                    activeColor: Colors.blue,
                    onChanged: (value){
                      setState(() {
                        selectedTime = (value/10).round()*10;
                      });
                    },
                  ),

                  Text(
                    'Шаг: 10 секунд',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _startTimer(selectedTime);
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
    HapticFeedback.heavyImpact();
    setState(() {
      _restTimeRemaining = seconds;
      _isResting = true;
    });
  }

  // ЗАВЕРШЕНИЕ ОТДЫХА
  void _endRestPeriod(){
    HapticFeedback.mediumImpact();
    setState(() {
      _isResting = false;
      _restTimeRemaining = 0;
    });
  }

  // ПЕРЕХОД К ПРЕДЫДУЩЕМУ УПРАЖНЕНИЮ
  void _previousExercise(){
    HapticFeedback.lightImpact();
    if (_currentExerciseIndex > 0){
      setState(() => _currentExerciseIndex--);
      _scrollToCurrentExercise(_currentExerciseIndex);
    }
  }

  // ПЕРЕХОД К СЛЕДУЮЩЕМУ УПРАЖНЕНИЮ
  void _nextExercise(){
    HapticFeedback.mediumImpact();
    if (_currentExerciseIndex < _exercisesProgress.length -1){
      setState(() => _currentExerciseIndex++);
      _scrollToCurrentExercise(_currentExerciseIndex);

    }
  }

  // ЗАВЕРШЕНИЕ ТРЕНИРОВКИ
  void _finishWorkout(){
    HapticFeedback.heavyImpact();
    final totalCompletedSets = _exercisesProgress.fold(0, (sum, p) => sum + p.completedSetsCount,);

    if (totalCompletedSets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Нечего сохранять, нет выполненных подходов'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3)),
      );
      return;
    }


    final duration = DateTime.now().difference(_workoutStartTime);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    final isTooShort = duration.inMinutes < 15;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isTooShort ? 'Тренировка слишком короткая':'Завершить тренировку?'),
        content:Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (isTooShort) ... [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 18,),
                    SizedBox(width: 8,),
                    Expanded(
                      child: Text(
                        'Тренировка короче 15 минут не учитываются в статистике времени.',
                        style: TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const Text('Хотите завершить тренировку?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed : () => Navigator.pop(context),
            child: const Text('Продолжить'),
          ),

          // КНОПКА ЗАВЕРШЕНИЯ ТРЕНИРОВКИ
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await StorageService.clearWorkoutSession();
              // 1. СОБИРАЕМ ДАННЫЕ
              List<Exercise> completedExercises = [];
              // ПРОХОДИМ ПО ВСЕМ УПРАЖНЕНИЯМ И СОБИРАЕМ ДАННЫЕ
              for(var progress in _exercisesProgress){
                final setsData = progress.completedSets.map((set) =>{
                  'reps': set.completedReps,
                  'weight': set.weight,
                  'setNumber': set.setNumber,
                }).toList();

                // ДОБАВЛЯЕМ В СПИСОК
                completedExercises.add(Exercise(
                  id: progress.exercise.id,
                  name: progress.exercise.name,
                  weight: progress.currentWeight,
                  sets: progress.completedSets.length,
                  reps: progress.totalReps,
                  restTime: progress.exercise.restTime,
                  completedSets: setsData,
                  isTimeBased: progress.exercise.isTimeBased,
                  targetSeconds: progress.exercise.targetSeconds,
                ));
              }

              final recordedDuration = isTooShort ? 0 : duration.inSeconds;

              // 2. СОХРАНЯЕМ В ИСТОРИЮ
              await StorageService.addToHistory(WorkoutHistory(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                templateId: widget.template.id,
                date: DateTime.now(),
                exercises: completedExercises,
                duration: recordedDuration,
              ),
              );

              // 3. ВОСПРОИЗВОДИМ ЗВУК ЗАВЕРШЕНИЯ
              SoundService.playWorkoutCompleteSound(context);

              // 4. УВЕДОМЛЕНИЕ О ЗАВЕРШЕНИИ ТРЕНИРОВКИ
              await NotificationService().showWorkoutCompleteNotification(
                title: 'Тренировка завершена!',
                body: '${widget.template.name}. Продолжительность: $minutes минут(ы) $seconds секунд(ы)',
                context: context,
              );

              // 6. ПОКАЗЫВАЕМ УВЕДОМЛЕНИЕ О СОХРАНЕНИИ
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        isTooShort
                            ? 'Сохранено без учёта времени ( меньше 15 минут)'
                            : 'Тренировка сохранена в историю'
                    ),
                    backgroundColor: isTooShort ? Colors.orange : Colors.green,
                    duration:const Duration(seconds: 4),
                  ),
                );
              }

              // 7. ПРОВЕРЯЕМ ИЗМЕНЕНИЯ ВЕСОВ
              final weightChanged = <String, double> {};

              for (var progress in _exercisesProgress){
                final originalWeight = progress.exercise.weight;
                final finalWeight = progress.currentWeight;

                if (finalWeight != originalWeight) {
                  weightChanged[progress.exercise.name] = finalWeight;
                }
              }
              // ЕСЛИ ЕСТЬ ИЗМЕНЕНИЯ — предлагаем сохранить в шаблон
              if (weightChanged.isNotEmpty && mounted) {
                await _showSaveWeightsDialog(weightChanged, duration);
              } else {
                _navigateToComplete(duration);
              }
            },
            child: const Text('Завершить и сохранить'),
          ),
        ],
      ),
    );
  }

  // ДИАЛОГ ПРЕДЛОЖЕНИЯ СОХРАНЕНИЯ ИЗМЕНЕНИЙ ВЕСА
  Future <void> _showSaveWeightsDialog(Map<String, double> weightChanged, Duration duration) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: Colors.blue),
            SizedBox(width: 8),
            Text('Обновить веса?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('За тренировку вы изменили вес в ${weightChanged.length}'
                '${_getExerciseWord(weightChanged.length)}:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // СПИСОК ИЗМЕНЕНИЙ
            ...weightChanged.entries.map((entry) {
              final exerciseName = entry.key;
              final newWeight = entry.value;

              // Ищем оригинальный вес из прогресса
              final originalWeight = _exercisesProgress
                  .firstWhere((p) => p.exercise.name == exerciseName)
                  .exercise
                  .weight;

              final diff = newWeight - originalWeight;
              final isIncrease = diff > 0;

              return Padding(
                padding: const EdgeInsetsGeometry.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.arrow_upward: Icons.arrow_downward,
                      size: 16,
                      color: isIncrease ? Colors.green: Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${originalWeight.toStringAsFixed(1)} → '
                          '${newWeight.toStringAsFixed(1)} кг',
                      style: TextStyle(
                        color: isIncrease ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            Text(
              'Сохранить новые веса в шаблон тренировки?',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // НЕ СОХРАНЯТЬ
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToComplete(duration);
              },
            child: const Text('Не сохранять'),
          ),

          // СОХРАНИТЬ
          ElevatedButton(
            onPressed: () async {
              await StorageService.updateTemplateWeights(
                widget.template.id,
                weightChanged,
              );
              if (mounted) Navigator.pop(context);
              if (mounted){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Веса обновлены в шаблоне "${widget.template.name}"'),
                    backgroundColor: Colors.green,
                  ),
                );
                _navigateToComplete(duration);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  // СКЛОНЕНИЕ СЛОВА "УПРАЖНЕНИЕ"
  String _getExerciseWord(int count){
    if (count % 10 == 1 && count % 100 != 11) return 'упражнение';
    if (count % 10 >= 2 && count %10 <= 4 &&
        (count %100 < 10 || count % 100 >= 20 )) return 'упражнениях';
    return 'упражнениях';
  }

  // СОХРАНЯЕМ ТЕКУЩИЙ ПРОГРЕСС В СЕССИЮ
  Future<void> _saveSession() async {
    // Собираем completedSets для каждого упражнения
    final completedSets = <String, List<Map<String, dynamic>>>{};
    final currentWeights = <String, double> {};

    for (var progress in _exercisesProgress) {
      final id = progress.exercise.id.toString();

      completedSets[id] = progress.completedSets.map((set) => {
        'reps': set.completedReps,
        'weight': set.weight,
        'setNumber': set.setNumber,
      }).toList();

      currentWeights[id] = progress.currentWeight;
    }

    await StorageService.saveWorkoutSession(WorkoutSession(
        templateId: widget.template.id,
        startedAt: _workoutStartTime,
        completedSets: completedSets,
        currentWeights: currentWeights));
  }

  // ОБРАБОТЧИК НАЖАТИЯ "НАЗАД"
  Future<bool> _onWillPop() async {
    HapticFeedback.mediumImpact();
    // Проверяем — был ли реальный прогресс
    final hasProgress = _exercisesProgress.any((p) => p.completedSets.isNotEmpty);

    if (!hasProgress) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange,),
            SizedBox(width: 8,),
            Text('Выйти из тренировки?'),
          ],
        ),
        content:  const Text(
          'Прогресс сохранён. При следующем входе вы сможетепродолжить с того же места'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Остаться'),
          ),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Выйти'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ЗАВЕРШЕНИЕ ПОДХОДА НА ВРЕМЯ
  Future<void> _completeTimeBasedSet(int index, int elepsedSeconds) async {
    HapticFeedback.heavyImpact();
    final progress = _exercisesProgress[index];

    if (elepsedSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Запустите секундомер и выполните упражнение'),
            backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // Сохраняем время как "повторения" для совместимости
      progress.addCompletedSet(elepsedSeconds, progress.currentWeight);
    });

    await _saveSession();

    // Остальная логика — такая же как в _completeSet
    final exercise = progress.exercise;
    final isLastSet = progress.completedSetsCount >= exercise.sets;

    if (isLastSet && exercise.isInAnyCircle) {
      final allDone = _exercisesProgress
          .where((p) => p.exercise.circleNumber == exercise.circleNumber)
          .every((p) => p.isCompleted);

      if (allDone) {
        _showCircleRestTimer (exercise.circleNumber);
        return;
      }
    }
    // предложение отдыха после завершения подхода
    if (progress.remainingSets > 0) {
      _startRestTimer(index);
    }
  }

  // РЕДАКТИРОВАНИЕ ВЕСА ЧЕРЕЗ ДИАЛОГ
  void _showWeightEditor(int index){
    HapticFeedback.lightImpact();
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

  // МЕТОД ДЛЯ СОЗДАНИЯ КРУГОВ ИЗ УПРАЖНЕНИЙ:
  void _createWorkoutCircles(){
    final circles = <WorkoutCircle>[];
    final groupedExercises = <int, List<ExerciseProgress>>{};

    // ГРУППИРУЕМ УПРАЖНЕНИЯ ПО КРУГАМ
    for (var progress in _exercisesProgress){
      if (progress.exercise.isInAnyCircle) {
        final circleNumber = progress.exercise.circleNumber;
        if (!groupedExercises.containsKey(circleNumber)) {
          groupedExercises[circleNumber] = [];
        }
        groupedExercises[circleNumber]!.add(progress);
      }
    }

    // СОРТИРУЕМ УПРАЖНЕНИЯ ВНУТРИ КРУГОВ ПО ПОРЯДКУ
    for(var circleNumber in groupedExercises.keys){
      groupedExercises[circleNumber]!.sort((a,b) {
        return a.exercise.circleOrder.compareTo(b.exercise.circleOrder);
      });
    }
    // СОЗДАЕМ ОБЪЕКТЫ КРУГОВ
    for (var circleNumber in groupedExercises.keys){
      final exercisesInCircle = groupedExercises[circleNumber]!;

      // ПРЕОБРАЗУЕМ ExerciseProgress В Exercise ДЛЯ КРУГА
      final circleExercises = exercisesInCircle
          .map((progress) => progress.exercise)
          .toList();

      circles.add(WorkoutCircle(
        number: circleNumber,
        exercises: circleExercises,
        restTime: 90,
      ));
    }

    // СОРТИРУЕМ КРУГИ ПО НОМЕРУ
    circles.sort((a, b) => a.number.compareTo(b.number));

    setState(() {
      _workoutCircles = circles;

      // ЕСЛИ ЕСТЬ КРУГИ, НАЧИНАЕМ С ПЕРВОГО
      if (_workoutCircles.isNotEmpty) {
        _isInCircleMode = true;
        _currentCircleIndex = 0;

        // УСТАНАВЛИВАЕМ ТЕКУЩЕЕ УПРАЖНЕНИЕ КАК ПЕРВОЕ В КРУГЕ
        final firstExerciseInCircle = _workoutCircles[0].exercises[0];
        _currentExerciseIndex = _exercisesProgress.indexWhere(
              (progress) => progress.exercise.id == firstExerciseInCircle.id,
        );
      }
    });
  }

  //ДИАЛОГ ВОССТАНОВЛЕНИЯ СЕССИИ
  void _showRestoreSessionDialog(WorkoutSession session) {
    // Считаем сколько подходов было сделано
    final totalSets = session.completedSets.values
        .fold(0, (sum, sets) => sum + sets.length);

    // Сколько времени прошло
    final elapsed = DateTime.now().difference(session.startedAt);
    final hoursAgo = elapsed.inHours;
    final minutesAgo = elapsed.inMinutes%60;
    final timeLabel = hoursAgo > 0
        ? '$hoursAgoч $minutesAgoмин назад'
        : '${elapsed.inMinutes}мин назад';

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restore, color: Colors.blue),
              SizedBox(width: 8,),
              Text('Незавершенная тренировка'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('Найдена сессия от $timeLabel'),
              const SizedBox(height: 8,),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fitness_center, color: Colors.blue, size: 16,),
                    const SizedBox(width: 8,),
                    Text(
                      'Выполнено подходов:$totalSets',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12,),
              const Text(
                'Восстановить прогресс?',
                style:  TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            // НАЧАТЬ ЗАНОВО
            TextButton(
                onPressed: (){
                  Navigator.pop(dialogContext);
                  StorageService.clearWorkoutSession();
                },
                child: const Text('Начать заново'),
            ),
            // ВОССТАНОВИТЬ
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _restoreSession(session);
                },
                child: const Text('Восстановить'),
            ),
          ],
        ),
    );
  }

  //ВОССТАНОВЛЕНИЕ СЕССИИ
  void _restoreSession(WorkoutSession session){
    // Восстанавливаем время начала из сессии
    _workoutStartTime = session.startedAt;

    setState(() {
      for (int i = 0; i < _exercisesProgress.length; i++) {
        final id = _exercisesProgress[i].exercise.id.toString();

        // Восстанавливаем вес
        if (session.currentWeights.containsKey(id)) {
          _exercisesProgress[i] = _exercisesProgress[i].copyWith(
            currentWeight: session.currentWeights[id]!,
          );
        }

        // Восстанавливаем подходы
        final savedSets = session.completedSets[id] ?? [];
        for (var set in savedSets) {
          _exercisesProgress[i].addCompletedSet(
              set['reps'] as int,
              (set['weight'] as num).toDouble(),
          );
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentExercise(_currentExerciseIndex);
    });
  }

// ВСПОМОГАТЕЛЬНЫЙ МЕТОД — НАВИГАЦИЯ НА ЭКРАН ЗАВЕРШЕНИЯ
  void _navigateToComplete (Duration duration) async {
    HapticFeedback.heavyImpact();
    if (!mounted) return;
      // Считаем статистику
      int totalSets = 0;
      double totalVolume = 0;
      for (var p in _exercisesProgress) {
        totalSets += p.completedSets.length;
        for (var set in p.completedSets) {
          totalVolume += (set.completedReps * set.weight);
        }
      }

    // ВЫЧИСЛЯЕМ ПРОГРЕСС относительно предыдущей тренировки
    final progressPercent = await _calculateProgress(totalVolume);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutCompleteScreen(
            templateName: widget.template.name,
            durationSeconds: duration.inSeconds,
            totalSets: totalSets,
            totalExercise: _exercisesProgress.length,
            totalVolume: totalVolume,
            progressPercent: progressPercent,
          ),
        ),
      );
  }

  // ЗАПУСК ТАЙМЕРА ЗАТЕМНЕНИЯ
  void _resetDimTimer() {
    _dimTimer?.cancel();
    if(_isDimmed){
      setState(() => _isDimmed = false);// снимаем затемнение при касании
    }
    if (!_dimEnabled) return;

    _dimTimer = Timer( Duration(seconds: _dimAfterSeconds), () {
      HapticFeedback.vibrate();
      if (mounted) setState(() => _isDimmed = true);
    });
  }

  // СЧИТАЕМ ОБЪЁМ ЧЕРЕЗ completedSets (фактические данные)
  double _calcActualVolume(WorkoutHistory h) {
    double vol = 0;
    for (var ex in h.exercises) {
      if (ex.completedSets.isNotEmpty) {
        for (var set in ex.completedSets) {
          final reps = (set['reps'] as num).toDouble();
          final weight = (set['weight'] as num).toDouble();
          vol += reps * weight;
        }
      }
    }
    return vol;
  }

  // НОВЫЙ МЕТОД — считает % изменения объёма относительно прошлой тренировки
  Future<double?> _calculateProgress(double currentVolume) async {
    try{
      final history = await StorageService.loadHistory();

      // Ищем предыдущую тренировку по тому же шаблону
      final sameTemplate  = history
        .where((h) => h.templateId == widget.template.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));// Новые первыми

      if (sameTemplate.length < 2) return null; // Первая тренировка

      final prevVolume = _calcActualVolume(sameTemplate[1]);

      if (prevVolume == 0) return null;// Нет данных

      // Процент изменения: (новый - старый) / старый * 100
      return ((currentVolume - prevVolume)/prevVolume)*100;
    } catch (_) {
      return null;
    }
  }

  // СКРОЛЛ К ВЫБРАННОЙ КАРТОЧКЕ — карточка окажется по центру экрана
  void _scrollToCurrentExercise(int index) {
    if (index >= _exerciseKeys.length) return;

    // Небольшая задержка — ждём пока setState отрисует изменение
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _exerciseKeys[index];
      final context = key.currentContext;
      if (context == null) return;

      // Находим RenderBox карточки — он знает где карточка на экране
      final renderBox = context.findRenderObject() as RenderBox? ;
      if (renderBox == null) return;

      // Позиция карточки относительно ListView
      final cardOffset = renderBox.localToGlobal(Offset.zero);
      final cardHeight = renderBox.size.height;

      // Высота экрана и текущий скролл
      final screenHeight = MediaQuery.of(context).size.height;
      final currentScroll = _scrollController.offset;

      // Вычисляем куда скроллить чтобы карточка оказалась по центру
      final targetScroll = currentScroll +
        cardOffset.dy -
        screenHeight / 2 +
        cardHeight / 2;

      _scrollController.animateTo(
          targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
      );
    });
  }

  // УДАЛЕНИЕ ПОСЛЕДНЕГО ПОДХОДА
  void _deleteLastSet(int index) {
    final progress = _exercisesProgress[index];

    if (progress.completedSets.isEmpty) return;

    final lastSet = progress.completedSets.last;
    final setNumber = progress.completedSets.length;

    // Формируем описание подхода для диалога
    final setDecription = progress.exercise.isTimeBased
        ? 'Подход $setNumber: ${_formatSeconds(lastSet.completedReps)}'
        : 'Подход $setNumber: ${lastSet.completedReps} повт. × '
          '${lastSet.weight.toStringAsFixed(1)} кг';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Удалить подход'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // КАКОЙ ПОДХОД УДАЛЯЕМ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress.exercise.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    setDecription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ПРЕДУПРЕЖДЕНИЕ
            Row(
              children: [
                const Icon(Icons.warning_amber,
                size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                      'Действие нельзя отменить',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() {
                  // Удаляем последний подход из списка
                  progress.completedSets.removeLast();
                });
                // Сохраняем обновлённую сессию
                await _saveSession();

                if(mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                          'Подход $setNumber удалён',
                        ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  // ВСПОМОГАТЕЛЬНЫЙ — форматирует секунды (уже есть в stats_screen, дублирую)
  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0 сек';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '$s сек';
    if (s == 0) return '$m мин';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildDeleteSetButton(int index, ExerciseProgress progress) {
    return Tooltip(
      message: 'Удалить последний подход',
      child: InkWell(
        onTap: () => _deleteLastSet(index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_forever_rounded,
              size: 16,
              color: Colors.red.shade400,
              ),
              const SizedBox(width: 1),
              // СЧЁТЧИК — сколько подходов выполнено (понятно что именно удалится)
              Text(
                '${progress.completedSetsCount}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
