//services/sound_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';


// СЕРВИС ДЛЯ УПРАВЛЕНИЯ ЗВУКОМ
class SoundService {
  static final List<AudioPlayer> _activePlayers = [];

  // ВОСПРОИЗВЕДЕНИЕ ЗВУКА НАЧАЛА ТАЙМЕРА
  static Future<void> playTimerStartSound(BuildContext context) async {
    if (!_isSoundEnabled(context)) return;
    await _playSound('sounds/start_timer.mp3');
  }

  // ВОСПРОИЗВЕДЕНИЕ ЗВУКА ЗАВЕРШЕНИЯ ТАЙМЕРА
  static Future<void> playTimerSound(BuildContext context) async {
    if (!_isSoundEnabled(context)) return;
    await _playSound('sounds/timer_beep.mp3');
  }

  // ВОСПРОИЗВЕДЕНИЕ ЗВУКА ЗАВЕРШЕНИЯ ТРЕНИРОВКИ
  static Future<void> playWorkoutCompleteSound(BuildContext context) async {
    if (!_isSoundEnabled(context)) return;
    await _playSound('sounds/workout_complete.mp3');
  }

  // УНИВЕРСАЛЬНЫЙ МЕТОД ВОСПРОИЗВЕДЕНИЯ
  static Future<void> _playSound(String assetPath) async {
    try {
      final player = AudioPlayer();
      _activePlayers.add(player);

      await player.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      player.play(AssetSource(assetPath));

      player.onPlayerComplete.listen((_){
        player.dispose();
        _activePlayers.remove(player);
      });
    } catch (e) {
      print('Ошибка воспроизведения $assetPath: $e');
      HapticFeedback.lightImpact();
    }
  }

  // ПРОВЕРКА НАСТРОЕК ЗВУКА
  static bool _isSoundEnabled(BuildContext context){
    try {
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );
      return settingsProvider.settings.soundEnabled;
    } catch (e) {
      return true;
    }
  }

  static void dispoce() {}
}