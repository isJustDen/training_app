//services/sound_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';


// СЕРВИС ДЛЯ УПРАВЛЕНИЯ ЗВУКОМ
class SoundService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;

  // ИНИЦИАЛИЗАЦИЯ (опционально, для предзагрузки)
  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        // Пробуем предзагрузить звуки
        await _player.setSource(AssetSource('sounds/timer_beep.mp3'));
        _initialized = true;
        print('SoundService инициализирован');
      } catch (e) {
        print('Не удалось инициализировать SoundService $e');
      }
    }
  }

  // ВОСПРОИЗВЕДЕНИЕ ЗВУКА НАЧАЛА ТАЙМЕРА
  static Future<void> playTimerStartSound(BuildContext context) async {
    // ПРОВЕРЯЕМ, ВКЛЮЧЕН ЛИ ЗВУК В НАСТРОЙКАХ
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    if (!settingsProvider.settings.soundEnabled){
      print('Звук отключён в настройках');
      return;
    }

    try{
      await _player.stop();
      //остановка предыдущего звука
      await _player.setAudioContext(
          AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          )
        )
      );
      // Воспроизводим звук
      await _player.play(AssetSource('sounds/start_timer.mp3'));
    } catch (e) {
      print('Ошибка вопроизведения $e');
      _playFallBackNotification();
    }
  }

  // ВОСПРОИЗВЕДЕНИЕ ЗВУКА ТАЙМЕРА
  static Future<void> playTimerSound(BuildContext context) async {
    // ПРОВЕРЯЕМ, ВКЛЮЧЕН ЛИ ЗВУК В НАСТРОЙКАХ
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    
    if (!settingsProvider.settings.soundEnabled){
      print('Звук отключён в настройках');
      return;
    }
    
    try{
      print('Пытаюсь воспроизвести звук таймера...');
      await _player.stop(); //остановка предыдущего звука
      await _player.setAudioContext(
          AudioContext(
              android: AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              )
          )
      );
      // Воспроизводим звук
      await _player.play(AssetSource('sounds/timer_beep.mp3'));
      print('Звук таймера воспроизведён');
    } catch (e) {
      print('Ошибка вопроизведения $e');
      _playFallBackNotification();
    }
  }

  // ВОСПРОИЗВЕДЕНИЕ ЗВУКА ЗАВЕРШЕНИЯ ТРЕНИРОВКИ
  static Future<void> playWorkoutCompleteSound(BuildContext context) async {
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false
    );

    if (!settingsProvider.settings.soundEnabled) {
      print('Звук отключён в настройках');
      return;
    }

    try {
      print('Пытаюсь воспроизвести звук завершенияю...');
      await _player.stop();
      await _player.setAudioContext(
          AudioContext(
              android: AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                audioFocus: AndroidAudioFocus.gainTransientMayDuck,
              )
          )
      );
      // Воспроизводим звук
      await _player.play(AssetSource('sounds/workout_complete.mp3'));
      print('Звук завершения воспроизведён');
    } catch (e) {
      _playFallBackNotification();
    }
  }

  // РЕЗЕРВНОЕ УВЕДОМЛЕНИЕ (без звука)
  static void _playFallBackNotification(){
    print("Звуковой сигнал");
        HapticFeedback.lightImpact();
  }

  // ОСТАНОВИТЬ ВСЕ ЗВУКИ
  static Future<void> stopAllSounds() async {
    try {
      await _player.stop();
    } catch (e){
      print('Ошибка в остановке звуков ($e)');
    }
  }

  // ОСВОБОДИТЬ РЕСУРСЫ
  static void dispoce(){
    _player.dispose();
  }





}