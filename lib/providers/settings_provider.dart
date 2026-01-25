//providers/settings_provider.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

// ПРОВАЙДЕР ДЛЯ УПРАВЛЕНИЯ НАСТРОЙКАМИ ПРИЛОЖЕНИЯ
// ChangeNotifier - уведомляет виджеты об изменениях
class SettingsProvider extends ChangeNotifier{
  AppSettings _settings = AppSettings();

  // ГЕТТЕР ДЛЯ ПОЛУЧЕНИЯ НАСТРОЕК
  AppSettings get settings => _settings;

  // КОНСТАНТЫ ДЛЯ КЛЮЧЕЙ ХРАНЕНИЯ
  static const String _settingsKey = 'app_settings';

  // ЗАГРУЗКА НАСТРОЕК ИЗ ХРАНИЛИЩА
  Future<void> loadSettings() async {
    try{
      final prefs = await StorageService.getPrefs();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null){
        final Map<String, dynamic> settingsMap =
            Map<String, dynamic>.from(jsonDecode(settingsJson));
        _settings = AppSettings.fromMap(settingsMap);
        notifyListeners(); // Уведомляем подписчиков об изменениях
        print('Настройки ЗАГРУЖЕНЫ $_settings');
      }
    } catch (e) {
      print('ОШИБКА загрузки настроек $e');
    }
  }

  // СОХРАНЕНИЕ НАСТРОЕК
  Future<void> saveSettings() async {
    try{
      final prefs = await StorageService.getPrefs();
      final settingsJson = jsonEncode(_settings.toMap());
      await prefs.setString(_settingsKey, settingsJson);
      print('Настройки СОХРАНЕНЫ: $_settings');
    } catch (e) {
      print('ОШИБКА при сохранении настроек $e');
    }
  }

  // ПЕРЕКЛЮЧЕНИЕ ТЕМНОЙ ТЕМЫ
  Future<void> toggleDarkMode() async {
    _settings = _settings.copyWith(isDarkMode: !_settings.isDarkMode);
    await saveSettings();
    notifyListeners();// Уведомляем об изменении тем
  }

  // ПЕРЕКЛЮЧЕНИЕ ЗВУКА
  Future<void> toogleSound() async {
    _settings = _settings.copyWith(soundEnabled: !_settings.soundEnabled);
    await saveSettings();
    notifyListeners();
  }

  // УСТАНОВКА ВРЕМЕНИ ОТДЫХА ПО УМОЛЧАНИЮ
  Future<void> setDefaultRestTime(int seconds) async {
    _settings = _settings.copyWith(defaultRestTime: seconds);
    await saveSettings();
    notifyListeners();
  }
}