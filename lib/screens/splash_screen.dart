//screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

//СПЛЭШ СКРИН ДЛЯ ПРИЛОЖЕНИЯ

class SplashScreen extends StatefulWidget{
  final Future <void> Function() onInit;
  final Widget nextScreen;

  const SplashScreen ({
   super.key,
   required this.onInit,
   required this.nextScreen
});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
  with TickerProviderStateMixin {
  // ----- АНИМАЦИОННЫЕ КОНТРОЛЛЕРЫ -----
  // Каждый контроллер управляет отдельным элементом анимации
  late AnimationController _logoController; // Для анимации появления логотипа (пружинный эффект)
  late AnimationController _pulseController; // Для пульсации логотипа (постоянное дыхание)
  late AnimationController _textController; // Для появления текста (слайд снизу)
  late AnimationController _progressController; // Для прогресс-бара (линейная загрузка)

  // ----- АНИМАЦИОННЫЕ ЗНАЧЕНИЯ -----
  // Эти значения будут меняться во времени
  late Animation<double> _logoScale; // Масштаб логотипа (изменение размера)
  late Animation<
      double> _logoOpacity; // Прозрачность логотипа (плавное появление)
  late Animation<double> _pulse; // Пульсация (циклическое изменение размера)
  late Animation<double> _textOpacity; // Прозрачность текста
  late Animation<Offset> _textSlide; // Позиция текста (для слайда)
  late Animation<double> _progressValue; // Значение прогресс-бара (от 0 до 1)

  // Флаг готовности приложения (инициализация завершена)
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // ===== ЛОГОТИП: появление с пружинным эффектом =====
    _logoController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900)
    );

    // Масштаб с пружинным эффектом (перелёт + возврат)
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut, // Пружинный эффект
    );

    // Прозрачность: быстро появляется в первой половине анимации
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.4), // Только первые 40% времени
      ),
    );

    // ===== ПУЛЬСАЦИЯ: бесконечное "дыхание" логотипа =====
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // 1.5 секунды на цикл
    )
      ..repeat(reverse: true); // Повторять бесконечно туда-сюда

    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // ===== ТЕКСТ: появление со слайдом снизу =====
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Прозрачность: плавное появление
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Сдвиг: от смещения вниз до нормального положения
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5), // Сдвиг на 50% вниз
      end: Offset.zero, // Нормальное положение
    ).animate(CurvedAnimation(
        parent: _textController, curve: Curves.easeOut));


    // ===== ПРОГРЕСС-БАР: линейное заполнение =====
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _progressValue = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  //УПРАВЛЕНИЕ ПОСЛЕДОВАТЕЛЬНОСТЬЮ
  void _startSequence() async {
    // ШАГ 1: Небольшая пауза перед началом (эффект накопления)
    await Future.delayed(const Duration(milliseconds: 200));

    // ШАГ 2: Запускаем анимацию логотипа
    _logoController.forward();

    // ШАГ 3: Пауза перед появлением текста
    await Future.delayed(const Duration(milliseconds: 500));

    // ШАГ 4: Запускаем анимацию текста
    _textController.forward();

    // ШАГ 5: Ещё пауза перед прогресс-баром
    await Future.delayed(const Duration(milliseconds: 300));

    // ШАГ 6: Запускаем прогресс-бар и инициализацию ПАРАЛЛЕЛЬНО
    _progressController.forward();
    await widget.onInit;

    // ШАГ 7: Дожидаемся окончания прогресс-бара
    await _progressController.forward();

    // ШАГ 8: Помечаем, что всё готово (меняем текст на "Готово!")
    setState(() => _isReady = true);

    // ШАГ 9: Короткая пауза, чтобы пользователь увидел "Готово!"
    await Future.delayed(const Duration(milliseconds: 300));

    // ШАГ 10: Переход на следующий экран (если виджет ещё существует)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, ___) => widget.nextScreen, // Какой экран показать

          // Анимация перехода: простое затухание
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child,);
          },

          // Длительность перехода
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  //ОЧИСТКА РЕСУРСОВ
  @override
  void dispoce() {
    // Обязательно освобождаем каждый контроллер
    _logoController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  //ПОСТРОЕНИЕ ИНТЕРФЕЙСА
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A3A5C),
      body: Stack(
        children: [
          // СЛОЙ 1: Фоновые декоративные элементы
          _buildBackGround(),

          // СЛОЙ 2: Основной контент (по центру)
          Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  // ЛОГОТИП с пульсацией
                  _buildLogo(),

              const SizedBox(height: 32),

          // НАЗВАНИЕ и слоган
          _buildText(),

          const SizedBox(height: 60),

          // ПРОГРЕСС-БАР
          _buildProgress(),
        ],
      ),
    ),]
    ,
    )
    ,
    );
  }

  //ДЕКОРАТИВНЫЙ ФОН
  Widget _buildBackGround() {
    return Stack(
      children: [
        // Большой круг сверху-справа
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.15), // Полупрозрачный центр
                  Colors.transparent, // Исчезает к краям
                ],
              ),
            ),
          ),
        ),

        // Маленький акцент снизу-слева
        Positioned(
          bottom: 100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.teal.withOpacity(0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Сетка точек (очень прозрачная)
        Opacity(
          opacity: 0.04,
          child: CustomPaint(
            size: Size(
              MediaQuery
                  .of(context)
                  .size
                  .width,
              MediaQuery
                  .of(context)
                  .size
                  .height,
            ),
            painter: _DotGridPainter(),
          ),
        ),
      ],
    );
  }

  //АНИМИРОВАННЫЙ ЛОГОТИП
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value, // Прозрачность из анимации
          child: Transform.scale(
            scale: _logoScale.value,
            child: ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Градиент от синего к бирюзовому
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: [Color(0xFF2979FF), Color(0xFF00BCD4)],
                  ),
                  // Свечение
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                // Иконка внутри круга
                child: const Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  //АНИМИРОВАННЫЙ ТЕКСТ
  Widget _buildText() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _textOpacity, // Прозрачность
          child: SlideTransition(
            position: _textSlide,
            child: SlideTransition(
              position: _textSlide,
              child: Column(
                children: [
                  // Название приложения
                  const Text(
                    'Дневничёк',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Слоган
                  Text(
                    'Твоя персональная записная книжка',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 1.2
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  //ПРОГРЕСС-БАР
  Widget _buildProgress() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Column(
            children: [
              // Тонкий прогресс-бар
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressValue.value,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF2979FF),
                  ),
                  minHeight: 3, // Толщина полоски
                ),
              ),
              const SizedBox(height: 16),
              // Текст статуса (меняется при _isReady = true)
              Text(
                _isReady ? 'Готов' : 'Загрузка...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.3),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

//РИСОВАЛЬЩИК СЕТКИ ТОЧЕК
class _DotGridPainter extends CustomPainter{
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.fill;

    const spacing = 28.0;  // Расстояние между точками

    // Двойной цикл для создания сетки
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  //НУЖНО ЛИ ПЕРЕРИСОВЫВАТЬ
  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}

