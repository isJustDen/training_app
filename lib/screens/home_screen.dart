//screens/home_screen.dart

import 'package:fitflow/models/workout_history.dart';
import 'package:fitflow/screens/categories_screen.dart';
import 'package:fitflow/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'stats_screen.dart';
import 'measurements_screen.dart';
import 'settings_screen.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';

// ГЛАВНЫЙ ЭКРАН
class HomeScreen  extends StatefulWidget{
  final AppData? preloadedData;
  const HomeScreen({super.key, this.preloadedData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
  with TickerProviderStateMixin {

  // ИНДЕКС ТЕКУЩЕЙ ВКЛАДКИ
  int _currentIndex = 0;

  late PageController _pageController;   // PageController управляет PageView — позволяет свайпать между страницами

  // AnimationController для анимации появления элементов
  late AnimationController _fabAnimController;
  late Animation<double> _fabScale;

  // ДАННЫЕ для передачи в StatsScreen
  List<Exercise> _allExercises = [];
  List<WorkoutHistory> _preloadedHistory = [];

  @override
  void initState() {
    super.initState();

    // PageController с начальной страницей 0
    _pageController = PageController(initialPage: 0);

    // Анимация FAB — появляется с пружинным эффектом
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScale = CurvedAnimation(
        parent: _fabAnimController,
        curve: Curves.elasticOut);
    _fabAnimController.forward();

    // ИСПОЛЬЗУЕМ ПРЕДЗАГРУЖЕННЫЕ ДАННЫЕ если есть
    if (widget.preloadedData != null) {
      _allExercises = widget.preloadedData!.exercises;
      _preloadedHistory = widget.preloadedData!.history;
    } else {
      _loadExercises();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  // ЗАГРУЖАЕМ УПРАЖНЕНИЯ ДЛЯ СТАТИСТИКИ
  Future<void> _loadExercises() async {
    final templates = await StorageService.loadTemplates();
    final all = <String, Exercise>{};
    for (var t in templates) {
      for (var e in t.exercises) {
        all.putIfAbsent(e.name, () => e);
      }
    }
    if (mounted) setState(() => _allExercises = all.values.toList());
  }

  // ПЕРЕКЛЮЧЕНИЕ ВКЛАДКИ — синхронизирует NavigationBar и PageView
  void _onTabChanged (int index){
    setState(() => _currentIndex = index);

    // animateToPage — плавный переход с анимацией
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut,
    );

    // Лёгкая вибрация при переключении вкладки
    HapticFeedback.mediumImpact();

    // ЗВУК ТОЛЬКО ДЛЯ ВКЛАДОК "Тренировки" И "Статистика" (индексы 0 и 1)
    if (index == 0 || index == 1){
      SoundService.playTabSwitchSound(context);
    }
  }

  // КОНФИГУРАЦИЯ ВКЛАДОК
  static const _tabs = [
    _TabConfig(icon: Icons.fitness_center_rounded,  label: 'Тренировки'),
    _TabConfig(icon: Icons.bar_chart_rounded,       label: 'Статистика'),
    _TabConfig(icon: Icons.straighten_rounded,      label: 'Замеры'),
    _TabConfig(icon: Icons.settings_rounded,        label: 'Настройки'),
  ];

  @override
  Widget build (BuildContext context){
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvoked: (dipPop) async {
        if (dipPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        // Убираем стандартный AppBar — у каждой вкладки свой
        body: PageView(
          controller: _pageController,
          // onPageChanged — срабатывает при свайпе, синхронизирует NavigationBar
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            // ВКЛАДКА 1: ТРЕНИРОВКИ
            const CategoriesScreen(),

            // ВКЛАДКА 2: СТАТИСТИКА
            StatsScreen(currentExercises: _allExercises, preloadedHistory: _preloadedHistory),

            // ВКЛАДКА 3: ЗАМЕРЫ
            const MeasurementsScreen(),

            // ВКЛАДКА 4: НАСТРОЙКИ
            const SettingsScreen(),
          ],
        ),

        // НИЖНЯЯ НАВИГАЦИЯ — Material 3 NavigationBar
        bottomNavigationBar: _buildNavigationBar(colorScheme),
      ),
    );
  }

  Widget _buildNavigationBar(ColorScheme colorScheme){
    return NavigationBar(
        selectedIndex: _currentIndex, //текущая активная вкладка
        onDestinationSelected: _onTabChanged,

        //Стиль виджета
        height: 64,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,

        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,//показывать подписи только у активной вкладки

        destinations: _tabs.map((tab) => NavigationDestination(
            icon: Icon(tab.icon, color: colorScheme.onSurfaceVariant),
            selectedIcon: Icon(tab.icon, color: colorScheme.primary),
            label: tab.label
        )).toList(),
    );
  }

  //МЕТОД ДИАЛОГА ВЫХОДА
  void _showExitDialog(BuildContext context) async {
    await SoundService.playAppExitSound(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 8),
            Text('Выйти из приложения?'),
          ],
        ),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Остаться'),
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                SystemNavigator.pop();
              },
              child: Text('Выйти'),
          ),
        ],
      ),
    );
  }
}

// ВСПОМОГАТЕЛЬНЫЙ КЛАСС — конфигурация одной вкладки
class _TabConfig{
  final IconData icon;
  final String label;
  const _TabConfig({required this.icon, required this.label});
}