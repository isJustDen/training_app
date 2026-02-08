//services/storage_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../models/workout_history.dart';

// КЛАСС ДЛЯ РАБОТЫ С ХРАНИЛИЩЕМ
class StorageService {
  // КОНСТАНТЫ - ключи для хранения
  static const String _templatesKey = 'workout_templates';

  static const String _historyKey = 'workout_history';

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
          name: 'Понедельник FullBody. Акцент: грудь',
          dayOfWeek: 'Понедельник',
          exercises: [
            Exercise(
              id: '1',
              name: 'Жим штанги лёжа',
              weight: 20,
              sets: 3,
              reps: 8,
            ),
            Exercise(
              id: '2',
              name: 'Тяга к поясу',
              weight: 10,
              sets: 3,
              reps: 8,
            ),
            Exercise(
              id: '3',
              name: 'Присед',
              weight: 22.5,
              sets: 3,
              reps: 8,
            ),
            Exercise(
              id: '4',
              name: 'Махи гантелей',
              weight: 10,
              sets: 3,
              reps: 12,
            ),
            Exercise(
              id: '5',
              name: 'Бицепс, Z-гриф',
              weight: 15,
              sets: 3,
              reps: 8,
            ),
            Exercise(
              id: '6',
              name: 'Подъём ног в висе',
              weight: 0,
              sets: 3,
              reps: 10,
            ),
            Exercise(
              id: '7',
              name: 'Трицепс (прямая рукоятка)',
              weight: 25,
              sets: 3,
              reps: 8,
            ),
          ],
          createdAt: now,
          updatedAt: now,
      ),

      WorkoutTemplate(
        id: '2',
        name: 'Среда FullBody. Акцент: спина',
        dayOfWeek: 'Среда',
        exercises: [
          Exercise(
            id: '8',
            name: 'Подтягивания широкие',
            weight: 0,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '9',
            name: 'Тяга грифа 1 к поясу',
            weight: 40,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '10',
            name: 'Отжимания от брусьев',
            weight: 0,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '11',
            name: 'Выпады',
            weight: 25,
            sets: 3,
            reps: 12,
          ),
          Exercise(
            id: '12',
            name: 'Тяга к подборотку',
            weight: 10,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '13',
            name: 'Гантели(бицепс)',
            weight: 15,
            sets: 3,
            reps: 10,
          ),
          Exercise(
            id: '14',
            name: 'Скручивания с паузой',
            weight: 0,
            sets: 3,
            reps: 8,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),

      WorkoutTemplate(
        id: '3',
        name: 'Пятница FullBody. Акцент: ноги+плечи',
        dayOfWeek: 'Пятница',
        exercises: [
          Exercise(
            id: '15',
            name: 'Становая тяга',
            weight: 40,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '16',
            name: 'Жим тренажёра',
            weight: 30,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '17',
            name: 'Армейский жим штанги',
            weight: 10,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '18',
            name: 'Штанга на бицепс',
            weight: 10,
            sets: 3,
            reps: 12,
          ),
          Exercise(
            id: '19',
            name: 'Жим гантелей',
            weight: 20,
            sets: 3,
            reps: 8,
          ),
          Exercise(
            id: '20',
            name: 'Тяга тренажера',
            weight: 50,
            sets: 3,
            reps: 10,
          ),
          Exercise(
            id: '21',
            name: 'Пресс (турник)',
            weight: 0,
            sets: 3,
            reps: 10,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  // ОЧИСТКА ВСЕХ ДАННЫХ
  static Future<void> clearAllData() async{
    final prefs = await _prefs;
    await prefs.remove(_templatesKey);
    await prefs.remove(_historyKey);
    print('Все данные очищены');
  }

  // СОХРАНЕНИЕ ИСТОРИИ ТРЕНИРОВОК
  static Future<void> saveHistory(List<WorkoutHistory> history) async {
    final prefs = await _prefs;
    final historyJson = history.map((h) => h.toMap()).toList();
    await prefs.setString(_historyKey, jsonEncode(historyJson));
    print('Сохранено ${history.length} записей истории');
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
    print('Сохраненная тренировка: ${data}');
      return data.map((item) => WorkoutHistory.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Ошибка загрузки истории ${e}');
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


}
