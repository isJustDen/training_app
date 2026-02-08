//screens/stats_screen.dart

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
  Map<String, ExerciseStats> _exerciseStats = {};
  bool _isLoading = true;

  // ПЕРИОД ДЛЯ ФИЛЬТРАЦИИ (дни)
  int _filterDays = 30;

  @override
  void initState(){
    super.initState();
    _loadData();
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
    print('история загружена: ${_workoutHistory.length} тренировок');

    // 3. ПОЛУЧАЕМ ТЕКУЩИЕ УПРАЖНЕНИЯ
    List<Exercise> currentExercise;

    if (widget.currentExercises != null && widget.currentExercises!.isNotEmpty){
      currentExercise = widget.currentExercises!;
      print('Используем ${currentExercise.length} упражнений и шаблонов');
    } else {
      currentExercise = _getCurrentExercisesFromLastWorkout();
      print('Используем ${currentExercise.length} упражнений из истории');
    }

    // 4. РАССЧИТЫВАЕМ СТАТИСТИКУ
    if (currentExercise.isNotEmpty) {
      _exerciseStats = StatsService.getAllExercisesStats(
          history: _workoutHistory,
          currentExercises: currentExercise
      );
      print('Статистика расчитана для ${_exerciseStats.length} упражнений');
    } else {
      print('Нет упражнений для расчёта статистики');
      _exerciseStats = {};
    }

    setState(() => _isLoading = false);
  }

  // // ПОЛУЧИТЬ ВСЕ УНИКАЛЬНЫЕ УПРАЖНЕНИЯ ИЗ ИСТОРИИ
  // List<Exercise> _getAllExercisesFromHistory(){
  //   Set<String> uniqueNames = {};
  //   List<Exercise> allExercises = [];
  //
  //   for (var workout in _workoutHistory){
  //     for (var exercise in workout.exercises){
  //       if (!uniqueNames.contains(exercise.name)){
  //         uniqueNames.add(exercise.name);
  //         allExercises.add(exercise);
  //       }
  //     }
  //   }
  //   return allExercises;
  // }

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
    final avgDuration = _workoutHistory.fold<int>(
      0, (sum, workout) => sum + workout.duration
    ) / (totalWorkouts > 0 ? totalWorkouts : 1);

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // НАЗВАНИЕ УПРАЖНЕНИЯ
            Text(
              exerciseName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
                  title: 'Средний вес',
                  value: '${stats.averageWeight} кг',
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
              value: stats.efficiency/100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getEfficiencyColor(stats.efficiency),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('0%', style: TextStyle(fontSize: 10)),
                Text(
                  'Эффективность: ${stats.efficiency}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getEfficiencyColor(stats.efficiency),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text('200%', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
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

  // ЦВЕТ ДЛЯ ЭФФЕКТИВНОСТИ
  Color _getEfficiencyColor(double efficiency){
    if (efficiency >= 120) return Colors.green;
    if (efficiency >= 90) return Colors.blue;
    if (efficiency >= 70) return Colors.orange;
    return Colors.red;
  }

  // ЦВЕТ ДЛЯ ПРОГРЕССА
  Color _getProgressColor(double progress){
    if (progress > 0) return Colors.green;
    if (progress < 0) return Colors.red;
    return Colors.grey;
  }

}


