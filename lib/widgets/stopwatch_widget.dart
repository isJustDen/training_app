//widgets/stopwatch_widget.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sound_service.dart';
import 'dart:ui' show FontFeature;

// ВИДЖЕТ СЕКУНДОМЕРА ДЛЯ УПРАЖНЕНИЙ НА ВРЕМЯ
class StopwatchWidget  extends StatefulWidget{
  final int targetSeconds; // Целевое время
  final VoidCallback? onTarget;// Колбэк при достижении цели
  final VoidCallback? onStop;// Колбэк при остановке (возвращает время)
  final Function(int)? onStopped;// Колбэк с итоговым временем

  const StopwatchWidget({
    super.key,
    required this.targetSeconds,
    this.onTarget,
    this.onStop,
    this.onStopped,
  });

  @override
  State<StopwatchWidget> createState() => _StopwatchWidgetState();
}

class _StopwatchWidgetState extends State<StopwatchWidget>
  with SingleTickerProviderStateMixin {

  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _targetReached = false; // Флаг что цель достигнута
  Timer? _timer;

  // AnimationController
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState(){
    super.initState();
    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose(){
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ЗАПУСК/ПАУЗА СЕКУНДОМЕРА
  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }

      setState(() => _elapsedSeconds++);

      // ПРОВЕРЯЕМ ДОСТИЖЕНИЕ ЦЕЛИ
      if (_elapsedSeconds == widget.targetSeconds && !_targetReached) {
        if (!mounted) return;
        _onTargetReached();
      }
    });
  }

  void _pauseTimer(){
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  // СБРОС СЕКУНДОМЕРА
  void _resetTimer() {
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _targetReached = false;
    });
  }

  // ОСТАНОВКА И СОХРАНЕНИЕ РЕЗУЛЬТАТА
  void _stopAndSave() {
    _timer?.cancel();
    _pulseController.stop();
    widget.onStopped?.call(_elapsedSeconds);
  }

  // ДОСТИЖЕНИЕ ЦЕЛЕВОГО ВРЕМЕНИ
  void _onTargetReached() {
    if (!mounted) return;
    _targetReached = true;
    SoundService.playTimerSound(context);
    widget.onTarget?.call();

    _pulseController.repeat(reverse: true);
  }

  // ФОРМАТИРОВАНИЕ ВРЕМЕНИ MM:SS
  String _formatTime(int seconds) {
    final m = seconds ~/60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build (BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = widget.targetSeconds > 0
        ? (_elapsedSeconds / widget.targetSeconds).clamp(0.0, 1.0)
        : 0.0;

    // Цвет меняется: синий → оранжевый → зелёный (при достижении цели)
    final color = _targetReached
      ? Colors.green
        : _elapsedSeconds > widget.targetSeconds * 0.8
        ? Colors.orange
        : colorScheme.primary;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: _targetReached ? 2:1,
          )
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ЗАГОЛОВОК
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_rounded, color: color, size: 18,),
                    const SizedBox(width: 6,),
                    Text(
                      _targetReached ? 'Цель достигнута! 🎯': 'Секундомер',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Целевое время
                Text(
                  'Цель: ${_formatTime(widget.targetSeconds)}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12,),

            // БОЛЬШОЙ ТАЙМЕР
            Text(_formatTime(_elapsedSeconds),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8,),

            // ПРОГРЕСС-БАР
            SizedBox(
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // КНОПКИ УПРАВЛЕНИЯ
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // СБРОС
                _buildControlButton(
                  icon: Icons.refresh_rounded,
                  label: 'Сброс',
                  color: colorScheme.onSurfaceVariant,
                  onTap: _resetTimer,
                ),

                // СТАРТ/ПАУЗА — главная кнопка
                GestureDetector(
                  onTap: _toggleTimer,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                // ЗАВЕРШИТЬ ПОДХОД
                _buildControlButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Зачесть',
                  color: Colors.green,
                  onTap: _elapsedSeconds > 0 ? () {_stopAndSave(); _resetTimer ();} : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}