//widgets/timer_widget.dart

import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/sound_service.dart';

// ВИДЖЕТ ТАЙМЕРА ОТСЧЕТА
class TimerWidget extends StatefulWidget {
  final int initialTime;
  final VoidCallback onComplete;
  final VoidCallback? onSkip;
  final String exerciseName;

  const TimerWidget({
    super.key,
    required this.initialTime,
    required this.onComplete,
    this.onSkip,
    this.exerciseName = 'Отдых',
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget>{
  late int _remainingTime;
  late DateTime _endTime;
  Timer? _timer;

  @override
  void initState(){   // initState() - ВЫЗЫВАЕТСЯ ПРИ СОЗДАНИИ ВИДЖЕТА
    super.initState();
    _initializeTimer();
  }

  // ИНИЦИАЛИЗАЦИЯ ТАЙМЕРА
  void _initializeTimer(){
    _remainingTime = widget.initialTime;
    _endTime = DateTime.now().add(Duration(seconds: widget.initialTime));
    _startTimer();
  }

  // ЗАПУСК ТАЙМЕРА
  void _startTimer() {
    // ВОСПРОИЗВОДИМ ЗВУК ПРИ ЗАПУСКЕ ТАЙМЕРА (ТОЛЬКО 1 РАЗ)
    SoundService.playTimerStartSound(context);
    // Timer.periodic - создает таймер, который срабатывает периодически
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      // ЕСЛИ ВИДЖЕТ УДАЛЕН - ОСТАНАВЛИВАЕМ ТАЙМЕР
      if (!mounted) {
        timer.cancel();
        return;
      }

      // ВЫЧИСЛЯЕМ ОСТАВШЕЕСЯ ВРЕМЯ
      final now = DateTime.now();
      final difference = _endTime.difference(now);
      _remainingTime = difference.inSeconds;

      // ЕСЛИ ВРЕМЯ ВЫШЛО
      if (_remainingTime <= 0) {
        timer.cancel();
        SoundService.playTimerSound(context);
        await _showCompleteNotification();

        widget.onComplete();
        return;
      }
      setState(() {});
    });
  }

  // ПОКАЗ УВЕДОМЛЕНИЯ О ЗАВЕРШЕНИИ
  Future<void> _showCompleteNotification() async {

  //ОСТАНАВЛИВАЕМ ТАЙМЕР ПРИ УДАЛЕНИИ ВИДЖЕТА
    try {
      await NotificationService().showTimerCompleteNotification(
        title: 'Таймер завершен',
        body: 'Отдых после ${widget.exerciseName} завершен. Возвращайтесь к тренировке!',
      );
    } catch (e) {
      print('Ошибка показа уведомления: $e');
    }
  }

  //ОСТАНАВЛИВАЕМ ТАЙМЕР ПРИ УДАЛЕНИИ ВИДЖЕТА
  @override
  void dispose(){
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    // ФОРМАТИРУЕМ ВРЕМЯ В ФОРМАТ MM:SS
    final minutes = (_remainingTime ~/60).toString().padLeft(2, '0');
    final seconds = (_remainingTime % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          // ИКОНКА ТАЙМЕРА
          const Icon(Icons.timer, color: Colors.orange),
          const SizedBox(width: 12),

          // ТЕКСТ С ОСТАВШИМСЯ ВРЕМЕНЕМ
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Отдых',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 25,
                      ),
                  ),
                  Text(
                    '$minutes:$seconds',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4,),
                ],
              ),
          ),

          // КНОПКА ПРОПУСКА
          if (widget.onSkip != null)
            IconButton(
                 onPressed: () {
                //   // ОТМЕНЯЕМ УВЕДОМЛЕНИЕ ПРИ ПРОПУСКЕ
                //   NotificationService.cancelScheduledNotification(
                //     widget.exerciseName.hashCode,
                //   );
                  widget.onSkip!();
                },
                icon: const Icon(Icons.stop, color: Colors.deepOrange, size: 40,),
                tooltip: 'Пропустить отдых',
            ),
        ],
      ),
    );
  }
}