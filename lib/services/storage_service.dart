//services/storage_service.dart

import 'dart:convert';
import'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';

// КЛАСС ДЛЯ РАБОТЫ С ХРАНИЛИЩЕМ
class StorageService {
  // КОНСТАНТЫ - ключи для хранения
  static const String _templatesKey = 'workout_templates';

  // МЕТОД ДЛЯ ПОЛУЧЕНИЯ ЭКЗЕМПЛЯРА SharedPreferences
  static Future <SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // СОХРАНЕНИЕ СПИСКА ШАБЛОНОВ
  static Future<void> saveTemplates(List<WorkoutTemplate> templates) async {
    // Получаем доступ к SharedPreferences
    final prefs = await _prefs;

    // Преобразуем список шаблонов в список Map
    final List<Map<String, dynamic>> templatesJson =
    templates.map((template) => template.toMap()).toList();

    // Преобразуем в JSON строку
    final String jsonString = jsonEncode(templatesJson);

    // Сохраняем строку в SharedPreferences
    await prefs.setString(_templatesKey, jsonString);

    print('Сохранено ${templates.length} шаблонов');
  }

  // ЗАГРУЗКА СПИСКА ШАБЛОНОВ
  static Future<List<WorkoutTemplate>> loadTemplates() async {
    // Получаем доступ к SharedPreferences
    final prefs = await _prefs;

    // Пытаемся получить сохраненные данные
    final String? jsonString = prefs.getString(_templatesKey);

    // ЕСЛИ ДАННЫХ НЕТ (первый запуск)
    if (jsonString == null){
      print('Нет сохранёных данных, создаём начальные шаблоны');
      return _getDefaultTemplates();
    }

    // ЕСЛИ ДАННЫЕ ЕСТЬ - пробуем их распарсить
    try{
      // Декодируем JSON строку
      final List<dynamic> jsonList = jsonDecode(jsonString);

      // Преобразуем каждый элемент в WorkoutTemplate
      final List<WorkoutTemplate> templates = jsonList
      .map((item) => WorkoutTemplate.fromMap(item))
      .toList();

      print('Загружено ${templates.length} шаблонов');
      return templates;
    } catch (e){
      // ЕСЛИ ОШИБКА ПАРСИНГА
      print('Ошибка парсинга $e');
      return _getDefaultTemplates();
    }
  }

  // НАЧАЛЬНЫЕ ШАБЛОНЫ ДЛЯ ПЕРВОГО ЗАПУСКА
  static List<WorkoutTemplate> _getDefaultTemplates(){
    final now = DateTime.now();

    return [
      WorkoutTemplate(
          id: '1',
          name: 'Тренировка груди',
          dayOfWeek: 'Понедельник',
          exercises: [
            Exercise(
              id: '1',
              name: 'Жим штанги лёжа',
              weight: 80,
              sets: 4,
              reps: 8,
            ),
            Exercise(
              id: '2',
              name: 'Разводка гантелей',
              weight: 20,
              sets: 3,
              reps: 10,
            ),
          ],
          createdAt: now,
          updatedAt: now,
      ),

      WorkoutTemplate(
        id: '2',
        name: 'Тренировка спины',
        dayOfWeek: 'Среда',
        exercises: [
          Exercise(
            id: '3',
            name: 'Тяга верхнего блока',
            weight: 60,
            sets: 4,
            reps: 8,
          ),
          Exercise(
            id: '4',
            name: 'Подтягивания',
            weight: 10,
            sets: 3,
            reps: 6,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // ОЧИСТКА ВСЕХ ДАННЫХ (для тестирования)
  static Future<void> clearAllData() async{
    final prefs = await _prefs;
    await prefs.remove(_templatesKey);
    print('Все данные очищены');
  }
}
