//screens/measurement_detail_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../services/measurement_service.dart';

//ЭКРАН ДЕТАЛЬНОГО ПРОСМОТРА ЗАМЕРА
class MeasurementDetailScreen  extends StatelessWidget{
  final Measurement measurement;
  final Map<String, double> changes;
  final Map<String, MeasurementEntry> compareValues;

  const MeasurementDetailScreen({
    super.key,
    required this.measurement,
    required this.changes,
    required this.compareValues,
  });

  @override
  Widget build(BuildContext context) {
    // ФОРМАТИРУЕМ ДАТУ для отображения
    final dateStr = '${measurement.date.day.toString().padLeft(2, '0')}.'
        '${measurement.date.month.toString().padLeft(2, '0')}.'
        '${measurement.date.year}';

    // ВЫЧИСЛЯЕМ ОБЩИЙ ПРОГРЕСС (среднее арифметическое всех изменений)
    final overall = MeasurementService.overallChange(changes);

    return Scaffold(
      appBar: AppBar(
        title: Text(dateStr),

        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Удалить замер',
          ),
        ],
      ),

      // ТЕЛО ЭКРАНА с прокруткой (SingleChildScrollView)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (changes.isNotEmpty) _buildVerdictCard(context, overall),
            if (changes.isNotEmpty) const SizedBox(height: 16,),

            _buildEntriesSection(context),

            // ЗАМЕТКИ (только если есть текст)
            if (measurement.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotesCard(context),
            ],

            // ФОТОГРАФИИ (только если есть фото)
            if (measurement.photoPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPhotosSection(context),
            ],
          ],
        ),
      ),
    );
  }

  //КАРТОЧКА ОБЩЕГО ПРОГРЕССА
  Widget _buildVerdictCard(BuildContext context, double overall){
    final isPositive = overall > 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up: Icons.trending_down;
    final sign = isPositive ? '+' : '';

    return Container(
      width: double.infinity, // Растягиваем на всю ширину
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Градиент от яркого цвета к прозрачному
        gradient: LinearGradient(
          colors:[color.withOpacity(0.2), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Общий прогресс',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$sign${overall.toStringAsFixed(1)}% относительно предыдущего замера',
                style: TextStyle(color: color, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //СЕКЦИЯ СО ВСЕМИ ПОКАЗАТЕЛЯМИ
  Widget _buildEntriesSection(BuildContext context){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ЗАГОЛОВОК СЕКЦИИ
        Row(
          children: [
            // Иконка зависит от типа замера
            Icon(
              measurement.type == MeasurementType.strength
                  ? Icons.fitness_center
                  : Icons.straighten,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8,),
            Text(
              measurement.type == MeasurementType.strength
                  ? 'Силовые показатели'
                  : 'Физические замеры',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // СПИСОК ПОКАЗАТЕЛЕЙ
        ...measurement.entries.entries.map((e) =>
        _buildEntryRow(context, e.key, e.value)),
      ],
    );
  }

  //СТРОКА ОДНОГО ПОКАЗАТЕЛЯ
  Widget _buildEntryRow(BuildContext context, String key, MeasurementEntry entry){
    // Ищем изменение для этого конкретного показателя
    final change = changes[key];
    final compareValue = compareValues[key]; // Используем переданные значения
    final hasChange = change != null && change != 0;
    final isPositive = (change ?? 0) > 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: hasChange
            ? Border.all(color: changeColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // НАЗВАНИЕ (слева, занимает всё доступное место)
          Expanded(child: Text(entry.name,
              style: TextStyle(fontSize: 14)),
          ),
          // ЗНАЧЕНИЕ (справа от названия)
          Text(
            entry.reps != null
                ? '${entry.value.toStringAsFixed(1)} ${entry.unit} × ${entry.reps} повт'
                : '${entry.value.toStringAsFixed(1)} ${entry.unit}',
            style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          ),

          // ИЗМЕНЕНИЕ (маленький чип с процентом)
          if (hasChange) ... [
            const SizedBox(width: 8,),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  // ПРЕДЫДУЩЕЕ ЗНАЧЕНИЕ (серым)
                  if (compareValue != null) ...[
                    Text(
                      '(было: ${compareValue.value.toStringAsFixed(1)}${compareValue.unit})',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  //КАРТОЧКА С ЗАМЕТКАМИ
  Widget _buildNotesCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.notes, size: 16,),
            SizedBox(width: 6,),
            Text('Заметки', style: TextStyle( fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(measurement.notes!),
        ],
      ),
    );
  }

  //СЕКЦИЯ С ФОТОГРАФИЯМИ
  Widget _buildPhotosSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(children: [
          Icon(Icons.photo_library, size: 16),
          SizedBox(width: 6),
          Text('Фотографии',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 12),

        // GridView.builder - эффективно создаёт сетку
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Запрещаем скролл внутри GridView (весь экран скроллится)
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 колонки
              crossAxisSpacing: 8, // Отступ между колонками
              mainAxisSpacing: 8, // Отступ между рядами
          ),
          itemCount: measurement.photoPaths.length, // Количество фото
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => _openPhoto(context, i), // Открыть фото на весь экран
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(measurement.photoPaths[i]), // Загружаем файл с диска
                  fit: BoxFit.cover,// Растягиваем, заполняя контейнер
              ),
            ),
          ),
        ),
      ],
    );
  }

  //ОТКРЫТИЕ ФОТО НА ПОЛНЫЙ ЭКРАН
  void _openPhoto(BuildContext context, int index){
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white, // Белая стрелка назад
          ),
          body: Center(
            child: InteractiveViewer(child: Image.file(File(measurement.photoPaths[index]))),
          ),
        ),
    ));
  }

  //ДИАЛОГ ПОДТВЕРЖДЕНИЯ УДАЛЕНИЯ
  Future <void> _confirmDelete(BuildContext context) async {
    // showDialog показывает диалог и возвращает результат выбора
    final confirm = await showDialog<bool>(
     context: context,
     builder: (ctx) => AlertDialog(
       title: const Text('Удалить замер?'),
       content: const Text('Это действие нельзя отменить.'),
       actions: [
         // КНОПКА ОТМЕНЫ
         TextButton(
             onPressed: () => Navigator.pop(ctx, false),
             child: const Text('Отмена'),
         ),
         // КНОПКА УДАЛЕНИЯ (красная)
         ElevatedButton(
             onPressed: () => Navigator.pop(ctx, true),
             child: const Text('Удалить',
               style: TextStyle(color: Colors.white)),
         ),
       ],
     ),
    );

    // Если пользователь подтвердил удаление
    if (confirm == true) {
      // Удаляем замер из базы данных
      await MeasurementService.delete(measurement.id);

      // Проверяем, что экран всё ещё существует (не закрыт)
      if (context.mounted) {
        Navigator.pop(context); // Закрываем текущий экран и возвращаемся к списку
      }
    }
  }
}