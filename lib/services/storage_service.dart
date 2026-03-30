//services/storage_service.dart

import 'dart:convert';
import 'package:fitflow/models/workout_category.dart';
import 'package:fitflow/models/workout_session.dart';
import 'package:fitflow/services/workout_presets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../models/workout_history.dart';
import 'exercise_database.dart';

// КЛАСС ДЛЯ РАБОТЫ С ХРАНИЛИЩЕМ
class StorageService {
  // КОНСТАНТЫ - ключи для хранения
  static const String _templatesKey = 'workout_templates';

  static const String _historyKey = 'workout_history';

  static const String _sessionKey = 'active_workout_session'; // КЛЮЧ для хранения активной сессии

  static const String _categoriesKey = 'workout_categories';

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

  }

  // ЗАГРУЗКА СПИСКА ШАБЛОНОВ
  static Future<List<WorkoutTemplate>> loadTemplates() async {
    // Получаем доступ к SharedPreferences
    final prefs = await _prefs;

    // Пытаемся получить сохраненные данные
    final String? jsonString = prefs.getString(_templatesKey);

    // ЕСЛИ ДАННЫХ НЕТ (первый запуск)
    if (jsonString == null){
      return WorkoutPresets.getDefaultTemplates();
    }

    // ЕСЛИ ДАННЫЕ ЕСТЬ - пробуем их распарсить
    try{
      // Декодируем JSON строку
      final List<dynamic> jsonList = jsonDecode(jsonString);

      // Преобразуем каждый элемент в WorkoutTemplate
      final List<WorkoutTemplate> templates = jsonList
      .map((item) => WorkoutTemplate.fromMap(item))
      .toList();

      return templates;
    } catch (e){
      // ЕСЛИ ОШИБКА ПАРСИНГА
      print('Ошибка парсинга $e');
      return WorkoutPresets.getDefaultTemplates();
    }
  }

  // ОЧИСТКА ВСЕХ ДАННЫХ
  static Future<void> clearAllData() async{
    final prefs = await _prefs;
    await prefs.remove(_templatesKey);
    await prefs.remove(_historyKey);
  }

  // СОХРАНЕНИЕ ИСТОРИИ ТРЕНИРОВОК
  static Future<void> saveHistory(List<WorkoutHistory> history) async {
    final prefs = await _prefs;
    final historyJson = history.map((h) => h.toMap()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
  }

  // ЗАГРУЗКА ИСТОРИИ ТРЕНИРОВОК
  static Future<List<WorkoutHistory>> loadHistory() async {
    final prefs = await _prefs;
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null){
      return [];
    }

    try{
      final List<dynamic> data = jsonDecode(historyJson);
      return data.map((item) => WorkoutHistory.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // ДОБАВЛЕНИЕ НОВОЙ ЗАПИСИ В ИСТОРИЮ
  static Future <void> addToHistory(WorkoutHistory workout) async {
    final history = await loadHistory();
    history.add(workout);
    await saveHistory(history);
  }

  // СТАТИЧЕСКИЙ МЕТОД ДЛЯ ДОСТУПА К PREFERENCES
  static Future<SharedPreferences> getPrefs() async{
    return await SharedPreferences.getInstance();
  }

  // ОЧИСТИТЬ ИСТОРИЮ ОДНОГО УПРАЖНЕНИЯ ПО ИМЕНИ
  static Future<void> clearExerciseHistory(String exerciseName) async {
    final history = await loadHistory();

      // Проходим по каждой тренировке и удаляем упражнение из неё
      final updatedHistory = history.map((workout) {
        final updatedExercises = workout.exercises
            .where((e) => e.name != exerciseName)
            .toList();
        return workout.copyWith(exercises: updatedExercises);
    }).toList();

      await saveHistory(updatedHistory);
  }

  // ОЧИСТИТЬ ТОЛЬКО ИСТОРИЮ ТРЕНИРОВОК (шаблоны не трогаем)
  static Future<void> clearHistoryOnly() async {
    final prefs = await _prefs;
    await prefs.remove(_historyKey);
  }

  // ОБНОВИТЬ ВЕСА УПРАЖНЕНИЙ В ШАБЛОНЕ
  static Future<void> updateTemplateWeights(
      String templateId,
      Map<String, double> updatedWeights,
      ) async {
    final templates = await loadTemplates();

    final updatedTemplates = templates.map((template) {
      if (template.id != templateId) return template;

      // Обновляем веса упражнений в нужном шаблоне
      final updatedExercises = template.exercises.map((exercise) {
        final newWeight = updatedWeights[exercise.name];
        if (newWeight != null && newWeight != exercise.weight) {
          return exercise.copyWith(weight: newWeight);
        }
        return exercise;
      }).toList();

      return template.copyWith(
        exercises: updatedExercises,
        updatedAt: DateTime.now(),
      );
      }).toList();

    await saveTemplates(updatedTemplates);
  }
//------------------------------СОСТОЯНИЕ ТЕКУЩЕЙ СЕССИИ--------------------------------------------//
  // СОХРАНИТЬ текущую сессию
  static Future<void> saveWorkoutSession(WorkoutSession session) async {
    await HapticFeedback.heavyImpact();
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(session.toMap());
    await prefs.setString(_sessionKey, json);
  }

  // ЗАГРУЗИТЬ сохранённую сессию (null если нет)
  static Future<WorkoutSession?> loadWorkoutSession(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_sessionKey);
    if (json == null) return null;

    final session = WorkoutSession.fromMap(jsonDecode(json));

    // Возвращаем только если сессия принадлежит этому шаблону
    if (session.templateId != templateId) return null;
    return session;
  }

  // УДАЛИТЬ сессию (после завершения или отказа от восстановления)
  static Future<void> clearWorkoutSession() async {
    await HapticFeedback.vibrate();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // ЗАГРУЗКА КАТЕГОРИЙ
  static Future<List<WorkoutCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_categoriesKey) ?? [];

    if (raw.isEmpty) {
      return WorkoutPresets.getDefaultCategories();
    }

    return raw.map((s) {
      try {
        return WorkoutCategory.fromMap(jsonDecode(s));
      } catch (_){
        return null;
      }
    }).whereType<WorkoutCategory>().toList();
  }

  // СБРОСИТЬ КАТЕГОРИИ ДО ЗАВОДСКИХ
  static Future<void> resetCategoriesToDefault() async {
    await saveCategories(WorkoutPresets.getDefaultCategories());
  }

  // СОХРАНЕНИЕ КАТЕГОРИЙ
  static Future<void> saveCategories(List<WorkoutCategory> categories) async {
    await HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final raw = categories.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_categoriesKey, raw);
  }

  // ОЧИСТИТЬ ВСЕ ДАННЫЕ
  static Future<void> factoryReset() async {
    await HapticFeedback.heavyImpact();
    final prefs = await _prefs;
    await prefs.clear();
  }

  // СБРОСИТЬ ШАБЛОНЫ УПРАЖНЕНИЙ ДО ЗАВОДСКИХ
  static Future<void> resetTemplatesToDefault() async {
    await HapticFeedback.heavyImpact();
    await saveTemplates(WorkoutPresets.getDefaultTemplates());
  }

  // ОЧИСТИТЬ СТАТИСТИКУ (только историю)
  static Future<void> clearStatsOnly() async{
    await HapticFeedback.heavyImpact();
    await HapticFeedback.heavyImpact();
    await clearHistoryOnly();
  }

// УДАЛИТЬ УПРАЖНЕНИЕ ПОЛНОСТЬЮ (из шаблонов и истории)
  static Future<void> deleteExerciseCompletely(String exerciseName) async {
    await HapticFeedback.heavyImpact();
    // 1. Удаляем из истории
    await clearExerciseHistory(exerciseName);

    // 2. Удаляем из всех шаблонов
    final templates = await loadTemplates();
    final updatedTemplates = templates.map((template) {
      final updatedExercises = template.exercises
          .where((e) => e.name != exerciseName)
          .toList();
      return template.copyWith(exercises: updatedExercises);
    }).toList();
    await saveTemplates(updatedTemplates);

    // 3. Удаляем из пользовательских упражнений (используем ExerciseDatabase)
    await ExerciseDatabase.deleteUserExercise(exerciseName);
  }

}
