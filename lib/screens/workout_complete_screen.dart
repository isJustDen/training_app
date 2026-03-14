//screens/workout_complete_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

//ЭКРАН ЗАВЕРШЕНИЯ ТРЕНИРОВКИ
class WorkoutCompleteScreen extends StatefulWidget{
  // Данные тренировки для отображения
  final String templateName; // Название шаблона (например "Понедельник FullBody")
  final int durationSeconds; // Длительность в секундах
  final int totalSets; // Всего выполнено подходов
  final int totalExercise; // Всего выполнено упражнений
  final double totalVolume; // Общий объём (кг × повторения)

  const WorkoutCompleteScreen ({
    super.key,
    required this.templateName,
    required this.durationSeconds,
    required this.totalSets,
    required this.totalExercise,
    required this.totalVolume,
  });

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

//СОСТОЯНИЕ ЭКРАНА
class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen>
  with TickerProviderStateMixin {

  // ----- КОНТРОЛЛЕРЫ АНИМАЦИЙ (управляют временем) -----
  late AnimationController _heroController;  // Появление главной иконки (героя)
  late AnimationController _statsController; // Появление карточек со статистикой
  late AnimationController _confettiController; // Анимация конфетти (бесконечная)
  late AnimationController _buttonController;  // Появление кнопки "На главную"
  late AnimationController _pulseController;  // Пульсация свечения вокруг иконки

  // ----- АНИМАЦИОННЫЕ ЗНАЧЕНИЯ (меняются во времени) -----
  late Animation<double> _heroScale; // Масштаб иконки (увеличение с эффектом пружины)
  late Animation<double> _heroOpacity;  // Прозрачность иконки
  late Animation<double> _statsOpacity; // Прозрачность статистики
  late Animation<Offset> _statsSlide;  // Сдвиг статистики (появление снизу)
  late Animation<double> _buttonOpacity; // Прозрачность кнопки
  late Animation<Offset> _buttonSlide;  // Сдвиг кнопки
  late Animation<double> _pulse; // Пульсация (масштаб свечения)

  // ----- КОНФЕТТИ -----
  final List <_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  // МОТИВАЦИОННЫЕ ФРАЗЫ (показываются случайно)
  static const List<String> _phrases = [
    'Ты сделал это! 🔥',
    'Зверь проснулся! 💪',
    'Легенда в деле! ⚡',
    'Ещё один шаг к цели! 🎯',
    'Сила растёт! 🚀',
    'Без боли нет роста! 👊',
  ];

  late String _motivationPhrase;  // Выбранная фраза

  //ИНИЦИАЛИЗАЦИЯ ПРИ СОЗДАНИИ
  @override
  void initState() {
   super.initState();
   _motivationPhrase = _phrases[_random.nextInt(_phrases.length)];
   _generateParticles(); // Создаём 60 частиц
   _setupAnimations(); // Настраиваем анимации
   _startSequence(); // Запускаем появление
   HapticFeedback.heavyImpact(); // Тяжёлая вибрация (эффект награды)
  }

  //СОЗДАНИЕ ЧАСТИЦ КОНФЕТТИ
  void _generateParticles(){
    for (int i = 0; i < 60; i++){
      _particles.add(_ConfettiParticle(
        // Начальная позиция: случайная по x, немного выше экрана по y
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.3, // Отрицательная = выше экрана

        // Скорость: горизонтальная (-0.004..0.004), вертикальная (0.004..0.012)
        vx: (_random.nextDouble() - 0.5) * 0.008,
        vy: 0.004 + _random.nextDouble() * 0.008,

        // Цвет из палитры (синий, голубой, зелёный, жёлтый, оранжевый, белый)
        color: [
          const Color(0xFF2979FF),
          const Color(0xFF00E5FF),
          const Color(0xFF69FF47),
          const Color(0xFFFFD740),
          const Color(0xFFFF6D00),
          Colors.white,
        ][_random.nextInt(6)],

        // Размер (4..10 пикселей)
        size: 4 + _random.nextDouble() * 6,

        // Начальное вращение
        rotation: _random.nextDouble()*math.pi * 2,

        // Скорость вращения
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.15,

        // Форма (true = прямоугольник, false = круг)
        isRect: _random.nextBool(),
      ));
    }
  }

  //НАСТРОЙКА ВСЕХ АНИМАЦИЙ
  void _setupAnimations() {
    // ===== ГЕРОЙ (иконка с кубком) =====
    _heroController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
    );
    _heroScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut) // Пружина
    );
    _heroOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heroController, curve: const Interval(0, 0.4)), // Быстрое появление
    );

    // ===== СТАТИСТИКА (карточки) =====
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600)
    );
    _statsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOut),
    );
    _statsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3), // Сдвиг вниз на 30%
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _statsController, curve: Curves.easeOut));

    // ===== КНОПКА =====
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(_buttonController);
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero
    ).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeOut));

    // ===== КОНФЕТТИ (бесконечная анимация) =====
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // ===== ПУЛЬСАЦИЯ свечения вокруг иконки =====
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true); // Бесконечный бумеранг (туда-сюда)

    _pulse = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
  }

  //ПОСЛЕДОВАТЕЛЬНОСТЬ ПОЯВЛЕНИЯ
  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _heroController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _statsController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _buttonController.forward();
  }

  //ОЧИСТКА РЕСУРСОВ
  @override
  void dispose() {
    _heroController.dispose();
    _statsController.dispose();
    _confettiController.dispose();
    _buttonController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  //ФОРМАТИРОВАНИЕ ВРЕМЕНИ
  String _formatDuration(int seconds){
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}м ${s.toString().padLeft(2, '0')}с';
  }

  //ПОСТРОЕНИЕ ИНТЕРФЕЙСА
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // СЛОЙ 1: Фоновый градиент
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.background,] // Светлее сверху
              ),
            ),
          ),

          // СЛОЙ 2: Конфетти (анимированное)
          AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _){
                // Обновляем позиции всех частиц
                for (var p in _particles) {
                  p.x += p.vx; // Горизонтальное движение
                  p.y += p.vy; // Вертикальное падение
                  p.rotation += p.rotationSpeed;  // Вращение

                  // Если частица упала ниже экрана
                  if (p.y > 1.1) {
                    p.y = -0.05; // Появляется сверху
                    p.x = _random.nextDouble(); // Новая случайная позиция
                  }
                }
                return CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                  painter: _ConfettiPainter(_particles), // Рисуем частицы
                );
              },
          ),

          // СЛОЙ 3: Основной контент
          SafeArea( // Учитывает вырезы экрана и системные панели
              child: SingleChildScrollView( // На случай маленького экрана
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // ГЕРОЙ — иконка с кубком и свечением
                    _buildHero(),

                    const SizedBox(height: 28,),

                    // ЗАГОЛОВОК (мотивационная фраза + название)
                    _buildTitle(),

                    const SizedBox(height: 36,),

                    // СТАТИСТИКА (4 карточки)
                    _buildStats(),

                    const SizedBox(height: 40,),

                    // КНОПКА "На главную"
                    _buildButton(),

                    const SizedBox(height: 30,),
                  ],
                ),
          ),
          ),
        ],
      ),
    );
  }

  //ГЛАВНАЯ ИКОНКА
  Widget _buildHero(){
    return AnimatedBuilder(
        animation: Listenable.merge([_heroController, _pulseController]),
        builder: (context, _){
          return Opacity(
            opacity: _heroOpacity.value,
            child:  Transform.scale(
              scale: _heroScale.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ВНЕШНЕЕ СВЕЧЕНИЕ (пульсирует)
                  ScaleTransition(
                    scale: _pulse,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                            colors: [
                              const Color(0xFF2979FF).withOpacity(0.3),
                              Colors.transparent,
                            ],
                        ),
                      ),
                    ),
                  ),
                  // СРЕДНИЙ КРУГ (основной)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2979FF), Color(0xFF00BCD4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                        color: const Color(0xFF2979FF).withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 8,
                        ),
                      ],
                    ),
                    // ИКОНКА ТРОФЕЯ
                    child: const Icon(
                      Icons.emoji_events_rounded, // Кубок
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
    );
  }

  //ЗАГОЛОВОК
  Widget _buildTitle() {
    final minutes = widget.durationSeconds ~/ 60;
    final seconds = widget.durationSeconds % 60;
    return AnimatedBuilder(
        animation: _heroController, // Появляется вместе с героем
        builder: (context, _) {
          return Opacity(
              opacity: _heroOpacity.value,
              child: Column(
                children: [
                  Text(
                    _motivationPhrase,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0.5,
                      height: 1.2, // Межстрочный интервал
                    ),
                  ),
                  const SizedBox(height: 10,),
                  Text(
                    widget.templateName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
          );
        }
    );
  }

  //КАРТОЧКИ СО СТАТИСТИКОЙ
  Widget _buildStats() {
    return FadeTransition(
      opacity: _statsOpacity,
      child: SlideTransition(
        position: _statsSlide,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              // ВЕРХНЯЯ СТРОКА
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.timer_outlined,
                    label: 'Время',
                    value: _formatDuration(widget.durationSeconds),
                    color: const Color(0xFF2979FF),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.fitness_center,
                    label: 'Упражнений',
                    value: '${widget.totalExercise}',
                    color: const Color(0xFF00BCD4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // НИЖНЯЯ СТРОКА
              Row(
                children: [
                  _buildStatCard(
                    icon: Icons.repeat_rounded,
                    label: 'Подходов',
                    value: '${widget.totalSets}',
                    color: const Color(0xFF69FF47),
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    icon: Icons.bolt_rounded,
                    label: 'Объём',
                    value: '${widget.totalVolume.toStringAsFixed(0)} кг',
                    color: const Color(0xFFFFD740),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //ОДНА КАРТОЧКА СТАТИСТИКИ
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)), // Тонкая граница
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20,),
            const SizedBox(height: 8,),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1
              ),
            ),
            const SizedBox(height: 4,),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //КНОПКА "НА ГЛАВНУЮ"
  Widget _buildButton() {
    return FadeTransition(
      opacity: _buttonOpacity,
      child: SlideTransition(
        position: _buttonSlide,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2979FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
              child: const Text(
                  'На главную',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
          ),
        ),
      ),
    );
  }
}
// ========== ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ ДЛЯ КОНФЕТТИ ==========
//МОДЕЛЬ ЧАСТИЦЫ КОНФЕТТИ
class _ConfettiParticle{
  double x, y;  // Текущая позиция (0..1)
  double vx, vy; // Скорость движения
  double size; // Размер в пикселях
  double rotation; // Текущий угол вращения
  double rotationSpeed; // Скорость вращения
  Color color; // Цвет
  bool isRect; // true = прямоугольник, false = круг

  _ConfettiParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.color, required this.size,
    required this.rotation, required this.rotationSpeed,
    required this.isRect,
  });
}

//РИСОВАЛЬЩИК КОНФЕТТИ
class _ConfettiPainter extends CustomPainter{
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  //ОТРИСОВКА КАДРА
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles){
      final paint = Paint()..color = p.color.withOpacity(0.85);

      // Конвертируем относительные координаты (0..1) в абсолютные пиксели
      final cx = p.x * size.width;
      final cy = p.y * size.height;

      canvas.save(); // Сохраняем текущую трансформацию

      // Применяем трансформации
      canvas.translate(cx, cy); // Перемещаем в точку частицы
      canvas.rotate(p.rotation); // Поворачиваем

      if (p.isRect) {
        // Рисуем прямоугольник (вытянутый по горизонтали)
        canvas.drawRect(
          Rect.fromCenter(
              center: Offset.zero ,
              width: p.size,
              height: p.size * 0.5
          ),
          paint,
        );
      } else {
        // Рисуем круг
        canvas.drawCircle(Offset.zero, p.size*0.5, paint);
      }

      canvas.restore(); // Восстанавливаем исходную трансформацию
    }
  }

  //НУЖНО ЛИ ПЕРЕРИСОВЫВАТЬ
  @override
  bool shouldRepaint(_ConfettiPainter old) => true;

}
