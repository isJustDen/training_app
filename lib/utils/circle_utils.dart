//utils/circle_utils.dart

import 'package:flutter/material.dart';

import '../models/exercise.dart';

// УТИЛИТЫ ДЛЯ РАБОТЫ С ГРУППИРОВКОЙ УПРАЖНЕНИЙ В КРУГИ
class CircleUtils {
  // ГРУППИРОВАТЬ УПРАЖНЕНИЯ ПО КРУГАМ ИЗ СПИСКА
  static Map<int, List<Exercise>> groupExercisesByCircle(List<Exercise> exercises){
    final Map<int, List<Exercise>> circles = {};

    for (var exercise in exercises) {
      if (exercise.isInAnyCircle) {
        final circleNumber = exercise.circleNumber;
        if (!circles.containsKey (circleNumber)) {
          circles[circleNumber] = [];
        }
        circles[circleNumber]!.add(exercise);
      }
    }

    // СОРТИРУЕМ УПРАЖНЕНИЯ ВНУТРИ КАЖДОГО КРУГА ПО ПОРЯДКУ
    for (var circleNumber in circles.keys){
      circles[circleNumber]!.sort((a, b) => a.circleOrder.compareTo(b.circleOrder));
    }
    return circles;
  }

  // ПОЛУЧИТЬ СПИСОК ВСЕХ НОМЕРОВ КРУГОВ
  static List<int> getAllCircleNumbers(List<Exercise> exercises){
    final Set<int> circleNumbers = {};

    for (var exercise in exercises){
      if (exercise.isInAnyCircle){
        circleNumbers.add(exercise.circleNumber);
      }
    }
    return circleNumbers.toList()..sort();
  }

  // СОЗДАТЬ НОВЫЙ КРУГ И ДОБАВИТЬ В НЕГО УПРАЖНЕНИЯ
  static List<Exercise> createNewCircle(List<Exercise> exercises, List<int> exerciseIndices){
    // НАХОДИМ СЛЕДУЮЩИЙ СВОБОДНЫЙ НОМЕР КРУГА
    final existingCircles = getAllCircleNumbers(exercises);
    final newCircleNumber = existingCircles.isEmpty ?1 : existingCircles.last + 1;

    // СОЗДАЕМ НОВЫЙ СПИСОК УПРАЖНЕНИЙ С ОБНОВЛЕННЫМИ ДАННЫМИ О КРУГЕ
    final List<Exercise> updatedExercises = List.from(exercises);

    for (int i = 0; i <exerciseIndices.length; i++){
      final index = exerciseIndices[i];
      if (index < updatedExercises.length){
        updatedExercises[index] = updatedExercises[index].copyWith(
          isInCircle: true,
          circleNumber: newCircleNumber,
          circleOrder: i + 1,
        );
      }
    }
    return updatedExercises;
  }

  // УДАЛИТЬ КРУГ (СБРОСИТЬ ВСЕ УПРАЖНЕНИЯ ИЗ ЭТОГО КРУГА)
  static List<Exercise> removeCircle(List<Exercise> exercises, int circleNumber){
    return exercises.map((exercise) {
      if (exercise.circleNumber == circleNumber){
        return exercise.copyWith(
          isInCircle: false,
          circleNumber: 0,
          circleOrder: 0,
        );
      }
      return exercise;
    }).toList();
  }

  // ПЕРЕМЕСТИТЬ УПРАЖНЕНИЕ ИЗ ОДНОГО КРУГА В ДРУГОЙ
  static List<Exercise> moveExerciseToCircle(
      List<Exercise> exercises,
      String exerciseId,
      int targetCircleNumber,
      ){
    // НАХОДИМ УПРАЖНЕНИЕ
    final exerciseIndex = exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return exercises;

    // ОПРЕДЕЛЯЕМ ПОРЯДКОВЫЙ НОМЕР В НОВОМ КРУГЕ
    final targetCircleExercises = exercises
      .where((e) => e.circleNumber == targetCircleNumber)
      .toList();
    final newOrder = targetCircleExercises.length + 1;

    // ОБНОВЛЯЕМ УПРАЖНЕНИЕ
    final List <Exercise> updatedExercises = List.from(exercises);
    updatedExercises [exerciseIndex] = updatedExercises[exerciseIndex].copyWith(
      circleNumber: targetCircleNumber,
      circleOrder: newOrder,
    );

    return updatedExercises;
  }

  // ПОЛУЧИТЬ ЦВЕТ ДЛЯ ОТОБРАЖЕНИЯ КРУГА
  static Color getCircleColor(int circleNumber) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[circleNumber % colors.length];
  }

  // ПОЛУЧИТЬ ИКОНКУ ДЛЯ КРУГА
  static IconData getCircleIcon(int circleNumber){
    final icons = [
      Icons.circle,
      Icons.hexagon,
      Icons.pentagon,
      Icons.square,
      Icons.diamond,
      Icons.star,
      Icons.flag,
      Icons.bolt,
    ];

    return icons[circleNumber % icons.length];
  }

  // ФОРМАТИРОВАТЬ ИНФОРМАЦИЮ О КРУГЕ ДЛЯ ОТОБРАЖЕНИЯ
  static String formatCircleInfo(int circleNumber, int exerciseCount){
    return 'Круг $circleNumber ($exerciseCount ${getExerciseWord(exerciseCount)})';
  }

  // ВСПОМОГАТЕЛЬНЫЙ МЕТОД ДЛЯ СКЛОНЕНИЯ СЛОВА "УПРАЖНЕНИЕ"
  static String getExerciseWord(int count){
    if (count % 10 == 1 && count % 100 != 11) return 'упражнение';
    if(count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'упражнения';
    }

    return 'упражнений';
  }
}