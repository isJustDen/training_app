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
  int _compareFromIndex=0;
  int _compareToIndex=1;

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

    // Защита от выхода за пределы
    final fromIdx = _compareFromIndex.clamp(0, measurements.length - 1);
    final toIdx = _compareToIndex.clamp(
        (fromIdx + 1).clamp(0, measurements.length-1 ),
                  measurements.length-1);

    for (final key in measurements[fromIdx].entries.keys) {
      final newVal = measurements[fromIdx].entries[key]?.value;
      final oldVal = measurements[toIdx].entries[key]?.value;
      print('key: $key | new: $newVal | old: $oldVal');
    }

    // Считаем изменения между выбранными замерами
    final changes = measurements.length >= 2
                  ? MeasurementService.compareTwoMeasurements(measurements[fromIdx], measurements[toIdx])
                  : <String, double> {};

    final startIdx = toIdx;
    final endIdx = fromIdx;

    List<Measurement> selectedPeriod;
    if (startIdx <= endIdx) {
      selectedPeriod = measurements.sublist(startIdx, endIdx + 1);
    } else {
      // Если индексы перепутаны (хотя по логике не должны), меняем их местами
      selectedPeriod = measurements.sublist(endIdx, startIdx + 1);
    }
    // Общая оценка за весь выбранный период
    final trend = MeasurementService.overallTrend(selectedPeriod); // Вычисляем среднее изменение по всем показателям

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ВЫБОР ПЕРИОДА СРАВНЕНИЯ
        if (measurements.length >= 2)
          _buildPeriodSelector(measurements),

        const SizedBox(height: 8),

        // КАРТОЧКА ОБЩЕЙ ОЦЕНКИ
        if (changes.isNotEmpty) _buildTrendCard(trend, changes, measurements[fromIdx].date,
            measurements[toIdx].date, type),

        const SizedBox(height: 8),

        // СПИСОК ЗАМЕРОВ
        ...measurements.asMap().entries.map((entry) {
          final index = entry.key;
          final m = entry.value;

          // Предыдущие значения для каждой карточки
          final prevValues = MeasurementService.getPriviousValues(measurements, index);

          // Изменения показываем только для выбранного "from"
          final cardChanges = index == fromIdx? changes : <String, double> {};

          return _buildMeasurementCard(m, cardChanges, prevValues);
        }),
      ],
    );
  }

  //КАРТОЧКА ОБЩЕГО ПРОГРЕССА
  Widget _buildTrendCard(double trend, Map<String, double> changes,
      DateTime fromData, DateTime toData, MeasurementType type) {
    final isPositive = trend > 0;
    final isStrength = type == MeasurementType.strength;

    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final sign = isPositive ? '+' : '';

    // Считаем сколько показателей улучшилось/ухудшилось
    final improved = changes.values.where((v) => v > 0).length;
    final decline = changes.values.where((v) => v<0).length;

    String _fmt (DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.15),color.withOpacity(0.05),]
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28,),
              const SizedBox(width: 10,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isStrength ? 'Силовой прогресс': 'Физический прогресс',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${_fmt(toData)} → ${_fmt(fromData)}',
                      style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

              // БОЛЬШАЯ ОЦЕНКА
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Text(
                  '$sign${trend.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (changes.length>1) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMiniStat('↑ Улучшилось', improved, Colors.green),
                const SizedBox(width: 12),
                _buildMiniStat('↓ Упало', decline, Colors.red),
                const SizedBox(width: 12),
                _buildMiniStat('→ Без изменений',
                    changes.length - improved-decline, Colors.grey),
              ],
            ),
          ],
        ],
      ),
    );
  }

  //КАРТОЧКА ИНФОРМАЦИИ О ИЗМЕНЕНИИ
  Widget _buildMiniStat(String label, int count, Color color){
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color)),
        ),
      ],
    );
  }

  //КАРТОЧКА ОДНОГО ЗАМЕРА
  Widget _buildMeasurementCard(Measurement m, Map<String, double> changes,
      Map<String, MeasurementEntry> prevValues){
    // Форматируем дату в формате ДД.ММ.ГГГГ
    final dateStr = '${m.date.day.toString().padLeft(2, '0')}.'
        '${m.date.month.toString().padLeft(2, '0')}.'
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
                    return _buildEntryChip(e.value, change, prevValues[e.key]);
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
  Widget _buildEntryChip(MeasurementEntry entry, double? change,
      MeasurementEntry? previous) {
    final hasChange = change != null && change != 0;
    final isPositive = (change ?? 0) > 0;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // ТЕКУЩЕЕ ЗНАЧЕНИЕ
          entry.reps != null
                  ? '${entry.name}: ${entry.value.toStringAsFixed(1)}${entry.unit}×${entry.reps}'
                  : '${entry.name}: ${entry.value.toStringAsFixed(1)}${entry.unit}',
                style: const TextStyle(fontSize: 11),
          ),

          // ПРЕДЫДУЩЕЕ ЗНАЧЕНИЕ (серым)
          if (previous != null) ...[
            const SizedBox(width: 4),
            Text(
              '(б: ${previous.value.toStringAsFixed(1)}${previous.unit})',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],

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

  //ВИДЖЕТ ВЫБОРА ПЕРИОДА
  Widget _buildPeriodSelector(List<Measurement> measurements){
    String _fromData(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

    return Card(
      child: Padding(
          padding: const EdgeInsetsGeometry.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Период сравнения',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // ВЫБОР "С" (более новый замер)
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('С',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        _buildDateDropdown(
                          measurements: measurements,
                          selectedIndex: _compareFromIndex,
                          maxIndex: measurements.length-2,
                          onChanged: (i) => setState(() {
                            _compareFromIndex = i;
                            // "по" не может быть новее чем "с"
                            if (_compareToIndex <= i){
                              _compareToIndex = i + 1;
                            }
                          }),
                        ),
                      ],
                    ),
                ),

                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),

                // ВЫБОР "ПО" (более старый замер)
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('По',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                          _buildDateDropdown(
                          measurements: measurements,
                          selectedIndex: _compareToIndex,
                          minIndex: _compareFromIndex + 1,
                          onChanged: (i) => setState(() =>
                          _compareToIndex = i),
                          ),
                      ],
                    ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDropdown({
    required List<Measurement> measurements,
    required int selectedIndex,
    int minIndex = 0,
    int maxIndex = -1,
    required ValueChanged<int> onChanged,
  }) {
    final effectiveMax =
      maxIndex <0? measurements.length - 1 : maxIndex;

    return DropdownButtonFormField <int>(
        value: selectedIndex.clamp(minIndex, effectiveMax),
        isDense: true,
        decoration: InputDecoration(
          contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: List.generate(measurements.length, (i) => i)
            .where((i) => i >= minIndex && i <= effectiveMax)
            .map((i) {
              final d = measurements[i].date;
              return DropdownMenuItem(
                value: i,
                child: Text(
                    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}',
                  style: const TextStyle(fontSize: 13),
                ),
              );
    }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
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