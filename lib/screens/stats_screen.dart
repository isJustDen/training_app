//screens/stats_screen.dart

import 'package:fitflow/services/history_service.dart';
import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import '../services/stats_service.dart';
import '../models/workout_history.dart';


// ЭКРАН СТАТИСТИКИ И ПРОГРЕССА
class StatsScreen extends StatefulWidget{
  final List<Exercise>? currentExercises;

  const StatsScreen({
    super.key,
    this.currentExercises,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>{
  // ДАННЫЕ ДЛЯ ОТОБРАЖЕНИЯ
  List<WorkoutHistory> _workoutHistory = [];
  List<Exercise> _localExercises = []; // локальная копия, обновляется при удалении
  Map<String, ExerciseStats> _exerciseStats = {};
  bool _isLoading = true;

  // ПЕРИОД ДЛЯ ФИЛЬТРАЦИИ (дни)
  int _filterDays = 30;

  // ИСТОРИЯ ПО КАЖДОМУ УПРАЖНЕНИЮ (для раскрывающегося списка)
  Map<String, List<Map<String, dynamic>>> _exerciseHistory = {};
  Set<String> _expandedExercises = {}; // КАКИЕ КАРТОЧКИ РАСКРЫТЫ


  @override
  void initState(){
    super.initState();
    _loadData();
  }

  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ УДАЛЕНИЯ ИЗ ШАБЛОНОВ
  Future <void> _removeExerciseFromTemplates(String exerciseName) async {
    final templates = await StorageService.loadTemplates();
    final updatedTemplates = templates.map((template) {
      final updatedExercises = template.exercises
          .where((e) => e.name != exerciseName)
          .toList();
      return template.copyWith(exercises: updatedExercises);
    }).toList();
    await StorageService.saveTemplates(updatedTemplates);
  }

  // ЗАГРУЗКА ДАННЫХ
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 1. ЗАГРУЖАЕМ ИСТОРИЮ ТРЕНИРОВОК
    final history = await StorageService.loadHistory();

    // 2. ФИЛЬТРУЕМ ПО ПЕРИОДУ
    final cutoffDate = DateTime.now().subtract(Duration(days: _filterDays));
    _workoutHistory = history
        .where((workout) => workout.date.isAfter(cutoffDate))
        .toList();
    // 3. ПОЛУЧАЕМ ТЕКУЩИЕ УПРАЖНЕНИЯ
    List<Exercise> currentExercise;

    if (_localExercises.isNotEmpty) {
      currentExercise = _localExercises;
    } else if (widget.currentExercises != null && widget.currentExercises!.isNotEmpty) {
      currentExercise = widget.currentExercises!;
      _localExercises = List.from(currentExercise); // инициализируем локальную копию
    } else {
      currentExercise = _getCurrentExercisesFromLastWorkout();
      _localExercises = List.from(currentExercise);
    }

    // 4. РАССЧИТЫВАЕМ СТАТИСТИКУ
    if (currentExercise.isNotEmpty) {
      _exerciseStats = StatsService.getAllExercisesStats(
          history: _workoutHistory,
          currentExercises: currentExercise
      );
    } else {
      _exerciseStats = {};
    }

    // 5. ЗАГРУЖАЕМ ИСТОРИЮ ДЛЯ КАЖДОГО УПРАЖНЕНИЯ
    _exerciseHistory = {};
    for (var exercise in currentExercise) {
      _exerciseHistory [exercise.name] =
          await HistoryService.getFullExerciseHistory(exercise.name);
    }

    setState(() => _isLoading = false);
  }

  // ПОЛУЧИТЬ УПРАЖНЕНИЯ ИЗ ПОСЛЕДНЕЙ ТРЕНИРОВКИ
  List<Exercise> _getCurrentExercisesFromLastWorkout(){
    if (_workoutHistory.isEmpty) return [];

    _workoutHistory.sort((a, b) => b.date.compareTo(a.date));  // Сортируем по дате (новые первыми)

    return _workoutHistory.first.exercises;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildContent(),
    );
  }

  // ВЕРХНЯЯ ПАНЕЛЬ
  AppBar _buildAppBar(){
    return AppBar(
      title: const Text('Статистика'),
      actions: [
        // КНОПКА ОЧИСТКИ ВСЕЙ СТАТИСТИКИ
        // IconButton(
        //     onPressed: _showClearAllDialog,
        //     icon: Icon(Icons.delete_sweep,  color: Theme.of(context).colorScheme.error,),
        //     tooltip: 'Очистить всю статистику тренировок?',
        // ),
      ],
    );
  }

  // ДИАЛОГ ОЧИСТКИ ВСЕЙ СТАТИСТИКИ
  // void _showClearAllDialog(){
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Очистить всю статистику?'),
  //       content: const Text(
  //           'Вся история тренировок будет удалена \n '
  //               'Шаблоны и упражнения останутся нетронутыми'
  //       ),
  //       actions: [
  //         TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Отмена'),
  //         ),
  //         ElevatedButton(
  //             onPressed: () async {
  //               await StorageService.clearHistoryOnly();
  //               Navigator.pop(context);
  //               await _loadData(); // перезагрузка экрана
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                 content: Text('Вся статистика очищена'),
  //                 backgroundColor:Colors.orange,
  //                 ),
  //               );
  //             },
  //             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //             child: const Text('Очистить')
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ДИАЛОГ ОЧИСТКИ ОДНОГО УПРАЖНЕНИЯ
  void _showDeleteExerciseDialog(String exerciseName) {
    showDialog
      (context: context,
        builder: (context) => AlertDialog(
          title: const Text('Удалить упражнение?'),
          content: Text(
            'Упражнение "$exerciseName" будет удалено:\n'
                '• Из всех шаблонов тренировок\n'
                '• Из истории тренировок\n\n'
                'При следующей тренировке оно создастся заново.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
            ),
            ElevatedButton(
                onPressed: () async {
                  await StorageService.deleteExerciseCompletely(exerciseName);

                  // УДАЛЯЕМ ИЗ ЛОКАЛЬНОГО СПИСКА — чтобы не появилось снова
                  _localExercises.removeWhere((e) => e.name == exerciseName);


                  Navigator.pop(context);
                  await _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Упражнение "${exerciseName}" удалено'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Удалить'),
            ),
          ],
        ),
    );
  }

  // ОСНОВНОЕ СОДЕРЖИМОЕ
  Widget _buildContent(){
    if (_isLoading){
      return const Center(child: CircularProgressIndicator());
    }
    if (_workoutHistory.isEmpty){
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ОБЩАЯ СТАТИСТИКА
          _buildOverallStats(),
          const SizedBox(height: 24),

          // СТАТИСТИКА ПО УПРАЖНЕНИЯМ
          _buildExercisesState(),
        ],
      ),
    );
  }

  // ПУСТОЕ СОСТОЯНИЕ
  Widget _buildEmptyState(){
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assessment, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
              'Нет данных для статистики',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
              'Проведите несколько тренировок\nчтобы увидеть статистику',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadData,
              child: const Text('Обновить'),
          ),
        ],
      ),
    );
  }

  // ОБЩАЯ СТАТИСТИКА
  Widget _buildOverallStats(){
    final totalWorkouts = _workoutHistory.length;
    final totalVolume = _workoutHistory.fold<double>(
      0, (sum, workout) => sum + workout.totalVolume
    );

    // ФИЛЬТРУЕМ — только реальные тренировки (duration > 0)
    final validWorkouts = _workoutHistory
      .where((w) => w.duration > 0)
      .toList();

    final avgDuration = validWorkouts.isEmpty
        ? 0.0
        : validWorkouts.fold<int>(0, (sum, w) => sum + w.duration)/
        validWorkouts.length;

    return Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Общая статистика',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  title: 'Всего тренировок',
                  value: totalWorkouts.toString(),
                  icon: Icons.fitness_center,
                  color: Colors.blue,
                ),
                _buildStatCard(
                  title: 'Ср. время трен.',
                  value: '${(avgDuration/60).toStringAsFixed(0)} мин',
                  icon: Icons.timer,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // КАРТОЧКА СТАТИСТИКИ
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    }){
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 15, color: Colors.grey),
        ),
      ],
    );
  }

  // СТАТИСТИКА ПО УПРАЖНЕНИЯМ
  Widget _buildExercisesState(){
    if (_exerciseStats.isEmpty){
      return Column(
        children: [
          const Center(child: Text('Нет данных по упражнениям')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Обновить данные'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Статистика по упражнениям',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Эффективность = (текущие повторения / средние повторения) × 100% ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          'Найдено ${_exerciseStats.length} упражнений',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        ..._exerciseStats.entries.map((entry){
          final exerciseName = entry.key;
          final stats = entry.value;

          return _buildExerciseStatsCard(exerciseName, stats);
        }).toList(),
      ],
    );
  }

  // КАРТОЧКА СТАТИСТИКИ УПРАЖНЕНИЯ
  Widget _buildExerciseStatsCard(String exerciseName, ExerciseStats stats){
    final isExpanded = _expandedExercises.contains(exerciseName);
    final history = _exerciseHistory[exerciseName] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // НАЗВАНИЕ УПРАЖНЕНИЯ + КНОПКА УДАЛЕНИЯ
                Row(
                  children: [
                    Expanded(child:
                    Text(
                      exerciseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ),

                    // КНОПКА СБРОСА ДАННЫХ УПРАЖНЕНИЯ
                    IconButton(
                      onPressed: () => _showDeleteExerciseDialog(exerciseName),
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade300,
                      tooltip: 'Полностью удалить упражнение',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // КНОПКА РАСКРЫТИЯ ИСТОРИИ
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedExercises.remove(exerciseName);
                      } else {
                        _expandedExercises.add(exerciseName);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'История',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded
                            ?Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ПОКАЗАТЕЛИ СТАТИСТИКИ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ЭФФЕКТИВНОСТЬ
                    _buildStatIndicator(
                      title: 'Эффективность',
                      value: '${stats.efficiency}%',
                      color: _getEfficiencyColor(stats.efficiency),
                      icon: Icons.trending_up,
                    ),

                    //СРЕДНИЙ ВЕС
                    _buildStatIndicator(
                      title: stats.isTimeBased ? 'Среднее время': 'Средний вес',
                      value: stats.isTimeBased
                          ? _formatSeconds(stats.averageWeight.toInt())
                          :'${stats.averageWeight} кг',
                      color: Colors.blue,
                      icon: Icons.fitness_center,
                    ),

                    // ПРОГРЕСС
                    _buildStatIndicator(
                      title: 'Прогресс',
                      value: '${stats.progress}%',
                      color: _getProgressColor(stats.progress),
                      icon: stats.progress >=0
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                  ],
                ),

                // ЛИНЕЙНЫЙ ИНДИКАТОР ЭФФЕКТИВНОСТИ
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: stats.efficiency/100.clamp(0.0, 1.0),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getEfficiencyColor(stats.efficiency),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0%', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(
                      'Эффективность: ${stats.efficiency}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getEfficiencyColor(stats.efficiency),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('200%', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),

          // РАСКРЫВАЮЩАЯСЯ ИСТОРИЯ
          if (isExpanded) _buildHistoryList(history, stats.isTimeBased),
        ],
      ),
    );
  }

  // ИНДИКАТОР СТАТИСТИКИ
  Widget _buildStatIndicator({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // СПИСОК ИСТОРИЧЕСКИХ ЗАПИСЕЙ
  Widget _buildHistoryList(
      List<Map<String, dynamic>> history, bool isTimeBased) {
    if(history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          ),
        ),
        child: Center(
          child: Text(
            'История пуста',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ЗАГОЛОВОК ТАБЛИЦЫ
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                const Icon(Icons.history, size: 14, color: Colors.grey),
                const SizedBox(width: 6),

                Text(
                  'История записей',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // СТРОКИ ИСТОРИИ
          ...history.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            final date = record['date'] as DateTime;
            final exercise = record['exercise'] as Exercise;
            final isEven = index % 2 == 0;

            return _buildHistoryRow(date, exercise, isTimeBased, isEven);
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // СТРОКА ИСТОРИИ
  Widget _buildHistoryRow(
      DateTime date, Exercise exercise, bool isTimeBased, bool isEven,){
    final colorScheme = Theme.of(context).colorScheme;

    // Форматируем дату
    final dateStr =
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    // Данные подходов
    final hasSets = exercise.completedSets.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isEven
        ? colorScheme.surfaceVariant.withOpacity(0.3)
        : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // СТРОКА 1: ДАТА + КРАТКОЕ РЕЗЮМЕ
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                ),
              ),
              const SizedBox(width: 10),

              // ПОДХОДЫ И ИТОГ
              if (isTimeBased) ... [
                Icon(Icons.timer_outlined,
                  size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${exercise.sets} подх.',
                  style: TextStyle(
                    fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                // Среднее время из подходов
                if (hasSets) ...[
                  Text(
                    '⌀ ${_formatSeconds(_avgSetTime(exercise))}',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ] else ...[
                Icon(Icons.fitness_center,
                  size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${exercise.sets} подх. × ${exercise.weight.toStringAsFixed(1)} кг',
                    style: TextStyle(
                      fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
          // СТРОКА 2: ДЕТАЛИ ПОДХОДОВ (если есть)
          if (hasSets) ... [
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: exercise.completedSets.asMap().entries.map((e) {
                final i = e.key;
                final set = e.value;
                final reps = set['reps'] as int;
                final weight = (set['weight'] as num).toDouble();

                final label = isTimeBased
                    ? '${i+1}: ${_formatSeconds(reps)}'
                    : '${i + 1}: ${reps}×${weight.toStringAsFixed(1)}кг';
                return Container(
                  padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5)),
                  ),
                  child: Text(label,
                    style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );





  }

  // СРЕДНЕЕ ВРЕМЯ ПОДХОДА
  int _avgSetTime(Exercise exercise) {
    if (exercise.completedSets.isEmpty) return 0;
    final total = exercise.completedSets
      .map((s) => s['reps'] as int)
      .fold(0, (a, b) => a+b);
    return total ~/ exercise.completedSets.length;
  }

  // ЦВЕТ ДЛЯ ЭФФЕКТИВНОСТИ
  Color _getEfficiencyColor(double efficiency){
    if (efficiency >= 120) return Colors.green;
    if (efficiency >= 90) return Colors.blue;
    if (efficiency >= 70) return Colors.orange;
    return Theme.of(context).colorScheme.error;
  }

  // ЦВЕТ ДЛЯ ПРОГРЕССА
  Color _getProgressColor(double progress){
    if (progress > 0) return Colors.green;
    if (progress < 0) return Theme.of(context).colorScheme.error;
    return Colors.grey;
  }

  // Форматирует секунды в читаемый вид: 90 → "1:30"
  String _formatSeconds(int seconds){
    if (seconds <= 0) return '0 секунд';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s} сек';
    if (s == 0) return '${m} мин';
    return '${m}: ${s.toString().padLeft(2, '0')}';
  }
}


