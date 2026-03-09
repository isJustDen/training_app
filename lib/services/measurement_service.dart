//services/measurement_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/measurement.dart';

class MeasurementService {
  static const String _key = 'measurements';

  // СОХРАНИТЬ ВСЕ ЗАМЕРЫ
  static Future <void> saveAll (List<Measurement> measurements) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(measurements.map((m) => m.toMap()).toList());
    await prefs.setString(_key, json);
  }

  // ЗАГРУЗИТЬ ВСЕ ЗАМЕРЫ
  static Future<List<Measurement>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    try{
      final list = jsonDecode(json) as List;
      return list.map((m) => Measurement.fromMap(m)).toList();
    } catch (e){
      return [];
    }
  }

  // ДОБАВИТЬ НОВЫЙ ЗАМЕР
  static Future <void> add(Measurement measurement) async {
    final all = await loadAll();
    all.add(measurement);
    // Сортируем по дате — новые первыми
    all.sort((a, b) => b.date.compareTo(a.date));
    await saveAll(all);
  }

  // УДАЛИТЬ ЗАМЕР ПО ID
  static Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((m) => m.id == id);
    await saveAll(all);
  }

  // ПОЛУЧИТЬ ВСЕ ЗАМЕРЫ ОДНОГО ТИПА
  static Future<List<Measurement>> getByType(MeasurementType type) async {
    final all = await loadAll();
    return all.where((m) => m.type == type).toList();
  }

  // СРАВНЕНИЕ ДВУХ ПОСЛЕДНИХ ЗАМЕРОВ
  static Map<String, double> compareLatestTwo(List<Measurement> measurements){
    if (measurements.length < 2) return {};

    // Берём два последних (список уже отсортирован по дате)
    final latest = measurements[0];
    final previous = measurements [1];

    final result = <String, double> {};

    for (final key in latest.entries.keys){
      final newVal = latest.entries[key]?.value;
      final oldVal = previous.entries[key]?.value;

      // Считаем процент только если оба значения есть и старое не ноль
      if (newVal != null && oldVal != null && oldVal != 0){
        result[key] = (newVal - oldVal) / oldVal * 100;
      }
    }
    return result;
  }

  // ОБЩИЙ ВЕРДИКТ — среднее изменение по всем показателям
  static double overallChange(Map<String, double> changes) {
    if (changes.isEmpty) return 0;
    final sum = changes.values.fold(0.0, (a, b) => a+ b);
    return sum / changes.length;
  }
}