//screens/measurements_screen.dart

import 'package:flutter/material.dart';
import '../models/measurement.dart';
import '../services/measurement_service.dart';
import 'add_measurement_screen.dart';
import 'measurement_detail_screen.dart';

// ГЛАВНЫЙ ЭКРАН ЗАМЕРОВ — список всех записей с табами
class MeasurementsScreen extends StatefulWidget{
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class  _MeasurementsScreenState extends State<MeasurementsScreen>
  with SingleTickerProviderStateMixin{

  late TabController _tabController;
  List<Measurement> _strengthMeasurements = [];
  List<Measurement> _physicalMeasurement = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // TabController для переключения между вкладками
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose(){
    _tabController.dispose();
    super.dispose();
  }

  Future <void> _loadData() async {
    setState(() => _isLoading = true);
    final strength = await MeasurementService.getByType(MeasurementType.strength);
    final physical = await MeasurementService.getByType(MeasurementType.physical);
    setState(() {
      _strengthMeasurements = strength;
      _physicalMeasurement = physical;
      _isLoading = false;
    });
  }

  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Замеры и прогресс'),
        bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.fitness_center), text: 'Силовые'),
              Tab(icon: Icon(Icons.straighten), text: 'Физические'),
            ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
          controller: _tabController,
          children: [
            _buildMeasurementList(
              measurements: _strengthMeasurements,
              type: MeasurementType.strength,
            ),
            _buildMeasurementList(
              measurements: _physicalMeasurement,
              type: MeasurementType.physical,
            ),
          ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _addMeasurement,
          icon: const Icon(Icons.add),
          label: const Text('Новый замер'),
      ),
    );
  }

  //ПОСТРОЕНИЕ СПИСКА ЗАМЕРОВ ДЛЯ ВКЛАДКИ
  Widget _buildMeasurementList({
    required List<Measurement> measurements,
    required MeasurementType type,
  }) {
    // Если замеров нет - показываем заглушку
    if (measurements.isEmpty) {
      return _buildEmptyState(type);
    }

    final changes = MeasurementService.compareLatestTwo(measurements); // Считаем изменения между последними двумя замерами
    final overall = MeasurementService.overallChange(changes); // Вычисляем среднее изменение по всем показателям

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (changes.isNotEmpty) _buildVerdictCard(overall, type),

        const SizedBox(height: 8),
        ...measurements.asMap().entries.map((entry) {
          final index = entry.key;
          final m = entry.value;

          final cardChanges = index == 0? changes : <String, double> {};

          return _buildMeasurementCard(m, cardChanges);
        }),
      ],
    );
  }

  //КАРТОЧКА ОБЩЕГО ПРОГРЕССА
  Widget _buildVerdictCard(double overall, MeasurementType type) {
    final isPositive = overall > 0;
    final isStrength = type == MeasurementType.strength;

    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final label = isPositive
        ? '+${overall.toStringAsFixed(1)}%'
        : '${overall.toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.15),color.withOpacity(0.05),]
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32,),
          const SizedBox(width: 12,),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStrength ? 'Силовой прогресс': 'Физический прогресс',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Относительно прошлого замера: $label',
                  style: TextStyle(fontSize: 13, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //КАРТОЧКА ОДНОГО ЗАМЕРА
  Widget _buildMeasurementCard(Measurement m, Map<String, double> changes){
    // Форматируем дату в формате ДД.ММ.ГГГГ
    final dateStr = '${m.date.day.toString().padLeft(2, '0')}.'
        '${m.date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell( // InkWell делает карточку кликабельной с ripple-эффектом
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Открываем детальный просмотр
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MeasurementDetailScreen(
                measurement: m,
                changes: changes,
              ),
            ),
          );
          _loadData();
        },
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ЗАГОЛОВОК — дата + иконки фото
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14,),
                    const SizedBox(width: 6,),
                    Text(
                      dateStr,
                           style: const TextStyle( fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const Spacer(), // Раздвигает элементы

                    // Если есть фотографии - показываем иконку и количество
                    if (m.photoPaths.isNotEmpty) ...[
                      Icon(Icons.photo_library, size: 14,
                        color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 4),
                      Text('${m.photoPaths.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                    ],
                    const SizedBox(width: 8),
                    // Стрелка вправо - признак кликабельности
                    Icon(Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),

                const SizedBox(height: 8),

                // ПРЕВЬЮ — первые 3 показателя
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: m.entries.entries.take(3).map((e) {
                    // Берём первые 3 записи из Map entries
                    final change = changes[e.key];
                    return _buildEntryChip(e.value, change);
                  }).toList(),
                ),

                // Если показателей больше 3 - показываем счётчик остальных
                if (m.entries.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top:4),
                    child: Text(
                      '+ ещё ${m.entries.length - 3} показателей',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
        ),
      ),
    );
  }

  //ЧИП ОДНОГО ПОКАЗАТЕЛЯ
  Widget _buildEntryChip(MeasurementEntry entry, double? change) {
    final hasChange = change != null && change != 0;
    final isPositive = (change ?? 0) > 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child:  Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.reps != null
                  ? '${entry.name}: ${entry.value.toStringAsFixed(1)}${entry.unit}×${entry.reps}'
                  : '${entry.name}: ${entry.value.toStringAsFixed(1)}${entry.unit}',
                style: const TextStyle(fontSize: 11),
          ),

          // Если есть изменение - показываем процент
          if (hasChange) ...[
            const SizedBox(width: 4,),
            Text(
                '${isPositive ?'+' : ''}${change!.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 10,
                color: changeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  //ЗАГЛУШКА ДЛЯ ПУСТОГО СПИСКА
  Widget _buildEmptyState(MeasurementType type){
    final isStrength = type == MeasurementType.strength;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isStrength ? Icons.fitness_center : Icons.straighten,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isStrength
              ? 'Нет силовых замеров'
              : 'Нет физических замеров',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8,),
          Text(
            'Нажмите "+" чтобы добавить первый замер',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  //ОБРАБОТЧИК ДОБАВЛЕНИЯ ЗАМЕРА
  void _addMeasurement() async {
    // Определяем тип по активному табу
    final type = _tabController.index == 0
        ? MeasurementType.strength
        : MeasurementType.physical;

    // Открываем экран добавления и ждём возврата
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMeasurementScreen(initialType: type),
      ),
    );

    // Перезагружаем данные (вдруг пользователь что-то добавил)
    _loadData();
  }
}