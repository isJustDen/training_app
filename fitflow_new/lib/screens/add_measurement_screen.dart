//screens/add_measurement_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/measurement.dart';
import '../services/measurement_service.dart';

//ЭКРАН ДОБАВЛЕНИЯ НОВОГО ЗАМЕРА
class AddMeasurementScreen  extends StatefulWidget{
  final MeasurementType initialType;
  const AddMeasurementScreen({super.key, required this.initialType});

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

//СОСТОЯНИЕ ЭКРАНА ДОБАВЛЕНИЯ
class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  // ----- ПОЛЯ СОСТОЯНИЯ -----
  late MeasurementType _selectedType; // Текущий выбранный тип замера
  DateTime _selectedDate = DateTime.now(); // Дата замера (по умолчанию сегодня)
  final _notesController = TextEditingController(); // Контроллер для заметок
  final _imagePicker = ImagePicker(); // Для работы с камерой/галереей
  final Map<String, TextEditingController> _valueControllers = {}; // Для значений
  final Map<String, TextEditingController> _repsControllers = {};  // Для повторений (только силовые)

  final List<Map<String, dynamic>> _customFields = []; //Кастомные поля, добавленные пользователем:
  final List<String> _photoPath = []; // Пути к выбранным фотографиям
  bool _isSaving = false; // Флаг сохранения (чтобы не было двойного нажатия)

  //ИНИЦИАЛИЗАЦИЯ ПРИ СОЗДАНИИ
  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _initControllers();
  }

  //СОЗДАНИЕ КОНТРОЛЛЕРОВ ДЛЯ СТАНДАРТНЫХ ПОЛЕЙ
  void _initControllers() {
    _valueControllers.clear();
    _repsControllers.clear();

    // Выбираем набор полей в зависимости от типа
    final fields = _selectedType == MeasurementType.strength
      ? MeasurementDefaults.strengthFields
      : MeasurementDefaults.physicalFields;

    // Для каждого стандартного поля создаём контроллеры
    for (final field in fields) {
      final key = field['key']!; // Ключ-идентификатор (например 'bench_press')
      _valueControllers[key] = TextEditingController();

      // Если это силовой тип - нужны ещё повторения
      if (_selectedType == MeasurementType.strength) {
        _repsControllers[key] = TextEditingController();
      }
    }
  }

  //ОЧИСТКА РЕСУРСОВ
  @override
  void dispose() {
    _notesController.dispose();
    for (final c in _valueControllers.values) c.dispose();
    for (final c in _repsControllers.values) c.dispose();
    super.dispose();
  }

  //ПОСТРОЕНИЕ ИНТЕРФЕЙСА
  @override
  Widget build (BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый замер'),
        actions: [
          // Кнопка сохранения в AppBar
          TextButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Сохранить',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body:SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ТИП ЗАМЕРА (переключатель)
            _buildTypeSelector(),
            const SizedBox(height: 16),

            // ДАТА (кликабельный контейнер)
            _buildDatePicker(),
            const SizedBox(height: 24),

            // СТАНДАРТНЫЕ ПОЛЯ (зависят от типа)
            _buildSectionTitle(
              _selectedType == MeasurementType.strength
                  ? 'Силовые показатели'
                  : 'Физические замеры',
              _selectedType == MeasurementType.strength
                ? Icons.fitness_center
                : Icons.straighten,
            ),
            const SizedBox(height: 12),
            _buildStandardFields(),

            const SizedBox(height: 24),

            // КАСТОМНЫЕ ПОЛЯ (добавленные пользователем)
            _buildSectionTitle('Свои показатели', Icons.add_circle_outline),
            const SizedBox(height: 12),
            _buildCustomFields(),
            _buildAddCustomFieldButton(),

            const SizedBox(height: 24),

            // ФОТОГРАФИИ
            _buildSectionTitle('Фотографии', Icons.photo_camera),
            const SizedBox(height: 12),
            _buildPhotoSection(),

            const SizedBox(height: 24),

            // ЗАМЕТКИ
            _buildSectionTitle('Заметки', Icons.notes),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Любые комментарии к замеру',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ) ,
    );
  }

  //ПЕРЕКЛЮЧАТЕЛЬ ТИПА ЗАМЕРА
  Widget _buildTypeSelector() {
    return SegmentedButton<MeasurementType>(
      segments: const [
        ButtonSegment(
          value: MeasurementType.strength,
          label: Text('Силовые'),
          icon: Icon(Icons.fitness_center),
        ),
        ButtonSegment(
          value: MeasurementType.physical,
          label: Text('Физические'),
          icon: Icon(Icons.straighten),
        ),
      ],
      selected: {_selectedType}, // Текущий выбранный тип (множество)
      onSelectionChanged: (val){
        setState(() {
          _selectedType = val.first; // Берём первый (и единственный) элемент
          _customFields.clear(); // Кастомные поля зависят от типа - сбрасываем
          _initControllers(); // Пересоздаём поля при смене типа
        });
      },
    );
  }

  //ВЫБОР ДАТЫ
  Widget _buildDatePicker() {
    // Форматируем дату в ДД.ММ.ГГГГ
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}.'
        '${_selectedDate.month.toString().padLeft(2, '0')}.'
        '${_selectedDate.year}';

    return InkWell(
      onTap: _pickDate, // Открыть календарь
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12,),
            Text('Дата замера: $dateStr',
            style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Icon(Icons.edit, size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  //ЗАГОЛОВОК СЕКЦИИ
  Widget _buildSectionTitle(String title, IconData icon){
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          )),
      ],
    );
  }

  //СТАНДАРТНЫЕ ПОЛЯ
  Widget _buildStandardFields() {
    final fields = _selectedType == MeasurementType.strength
        ? MeasurementDefaults.strengthFields
        :MeasurementDefaults.physicalFields;

    return Column(
      children: fields.map((field){
        final key = field['key']!;
        final name = field['name']!;
        final unit = field['unit']!;
        return  _buildFieldRow(
          key: key,
          name: name,
          unit: unit,
          isStrength: _selectedType == MeasurementType.strength,
          );
      }).toList(),
    );
  }

  //СТРОКА ВВОДА ОДНОГО ПОКАЗАТЕЛЯ
  Widget _buildFieldRow({
    required String key,
    required String name,
    required String unit,
    required bool isStrength,
    bool isCustom = false,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: 10),
      child: Row(
        children: [
          // НАЗВАНИЕ (гибкая ширина)
          Expanded(
            flex: 3,
            child: Text(name,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),

          // ЗНАЧЕНИЕ (поле ввода)
          Expanded(
            flex: 2,
            child: TextField(
              controller: _valueControllers[key],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                suffixText: unit,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              ),
            ),
          ),
          // ПОВТОРЕНИЯ (только для силовых)
          if (isStrength) ... [
            const SizedBox(width: 8),
            Expanded(
                flex: 2,
                child: TextField(
                  controller: _repsControllers[key],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixText: 'повт',
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
            ),
          ],

          // КНОПКА УДАЛЕНИЯ (для кастомных полей)
          if (onDelete != null) ...[
            const SizedBox(width: 4,),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  //КАСТОМНЫЕ ПОЛЯ
  Widget _buildCustomFields(){
    if (_customFields.isEmpty) return const SizedBox.shrink();

    return Column(
      children: _customFields.asMap().entries.map((entry){
        final i = entry.key;
        final field = entry.value;
        final key = 'custom_$i';

        return  _buildFieldRow(
          key: key,
          name: field['name'],
          unit: field['unit'] ?? '',
          isStrength: _selectedType == MeasurementType.strength,
          isCustom: true,
          onDelete: () => setState(() => _customFields.removeAt(i)),
        );
      }).toList(),
    );
  }

  //КНОПКА ДОБАВЛЕНИЯ КАСТОМНОГО ПОЛЯ
  Widget _buildAddCustomFieldButton() {
    return OutlinedButton.icon(
      onPressed: _showAddCustomFieldDialog,
      icon: const Icon(Icons.add, size: 18,),
      label: const Text('Добавить свой показатель'),
    );
  }

  //СЕКЦИЯ ФОТОГРАФИЙ
  Widget _buildPhotoSection(){
    return Column(
      children: [
        // СЕТКА ФОТО (если есть)
        if (_photoPath.isNotEmpty)
          GridView.builder(
            shrinkWrap: true, // GridView внутри Column
            physics: const NeverScrollableScrollPhysics(),// Не скроллим отдельно
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
            ),
               itemCount: _photoPath.length,
               itemBuilder: (context, i) => Stack(
                 fit: StackFit.expand,
                 children: [
                   // Само фото
                   ClipRRect(
                     borderRadius: BorderRadius.circular(8),
                     child: Image.file(File(_photoPath[i]),
                        fit: BoxFit.cover),
                   ),
                   // КНОПКА УДАЛЕНИЯ ФОТО (крестик в углу)
                    Positioned(
                      top: 2, right: 2,
                      child: GestureDetector(
                        onTap: () => setState(
                                () => _photoPath.removeAt(i)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                 ],
               ),
          ),

        const SizedBox(height: 8),

        // КНОПКИ ДОБАВЛЕНИЯ ФОТО
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Камера'),
            ),
            const SizedBox(width: 12,),

            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text('Галерея'),
            ),
          ],
        ),
      ],
    );
  }

  //ВЫБОР ДАТЫ ЧЕРЕЗ КАЛЕНДАРЬ
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        );
    if (picked != null) setState(() => _selectedDate = picked );
  }

  //ВЫБОР ФОТО (КАМЕРА ИЛИ ГАЛЕРЕЯ)
  Future<void> _pickImage(ImageSource source) async {
    final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 95,
    );
    if (image != null){
      setState(() => _photoPath.add(image.path));
    }
  }

  //ДИАЛОГ ДОБАВЛЕНИЯ КАСТОМНОГО ПОЛЯ
  void _showAddCustomFieldDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новый показатель'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
                hintText: 'Например: Жим гантелей',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(
                labelText: 'Единица измерения',
                hintText: 'кг, см, ...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
              onPressed: (){
                // Проверка на пустое название
                if (nameController.text.trim().isEmpty) return;

                final i = _customFields.length;
                final key = 'custom_$i';

                setState(() {
                  // Добавляем описание поля
                  _customFields.add({
                    'name': nameController.text.trim(),
                    'unit': unitController.text.trim(),
                  });

                  // Создаём контроллеры для нового поля
                  _valueControllers[key] = TextEditingController();
                  if (_selectedType == MeasurementType.strength) {
                    _repsControllers[key] = TextEditingController();
                  }
                });

                Navigator.pop(ctx);
              },
              child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  //СОХРАНЕНИЕ ЗАМЕРА
  Future<void> _save() async {
    setState(() => _isSaving = true);

    final entries = <String, MeasurementEntry> {};

    // ----- СТАНДАРТНЫЕ ПОЛЯ -----
    final fields = _selectedType == MeasurementType.strength
      ? MeasurementDefaults.strengthFields
      : MeasurementDefaults.physicalFields;

    for (final field in fields){
      final key = field['key']!;
      final raw = _valueControllers[key]?.text.trim() ?? '';
      if (raw.isEmpty) continue;

      final value = double.tryParse(raw);
      if (value == null) continue;

      final repsRaw = _repsControllers[key]?.text.trim()??'';

      // Пробуем преобразовать в целое число (int)
      final reps = int.tryParse(repsRaw);

      entries[key] = MeasurementEntry(
        name: field['name']!,
        value: value,
        reps: reps,
        unit: field['unit']!,
      );
    }

    //ОБРАБОТКА КАСТОМНЫХ ПОЛЕЙ
    for (int i = 0; i <_customFields.length; i++){
      final key = 'custom_$i';

      final raw = _valueControllers[key]?.text.trim()??'';
      if (raw.isEmpty) continue;

      // Пробуем преобразовать в число
      final value = double.tryParse(raw);
      if (value == null) continue;

      // Получаем повторения (если есть)
      final repsRaw = _repsControllers[key]?.text.trim()??'';
      final reps = int.tryParse(repsRaw);

      // Сохраняем кастомную запись
      entries[key] = MeasurementEntry(
          name: _customFields[i]['name'],
          value: value,
          reps: reps,
          unit: _customFields[i]['unit']??'',
      );
    }

    //ПРОВЕРКА НА НАЛИЧИЕ ДАННЫХ
    if (entries.isEmpty){
      setState(() => _isSaving = false); // Убираем индикатор сохранения

      // Показываем предупреждение пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните хотя бы один показатель'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    //СОХРАНЕНИЕ В БАЗУ ДАННЫХ
    final measurement = Measurement(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Генерируем уникальный ID на основе текущего времени в миллисекундах
        date: _selectedDate,  // Дата замера (выбранная пользователем в календаре)
        type: _selectedType,  // Тип замера (силовой или физический)
        entries: entries, // Все заполненные показатели (Map с записями)
        photoPaths: _photoPath, // Список путей к фотографиям (если пользователь добавил фото)
        notes: _notesController.text.trim().isEmpty // Заметки пользователя - если поле пустое, сохраняем null
          ? null
          : _notesController.text.trim(),
    );

    await MeasurementService.add(measurement); // Сохраняем через сервис (работа с базой данных)

    setState(() => _isSaving = false);

    if(mounted) {
      Navigator.pop(context);
    }
  }
}