//services/backup_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'storage_service.dart';
import 'measurement_service.dart';

// СЕРВИС РЕЗЕРВНОГО КОПИРОВАНИЯ
// Экспортирует все данные приложения в JSON файл и импортирует обратно
class BackupService {

  // ЭКСПОРТ — собираем все данные и сохраняем в файл
  static Future<BackupResult> exportToFile() async {
    try {
      // 1. СОБИРАЕМ ВСЕ ДАННЫЕ
      final templates   = await StorageService.loadTemplates();
      final history     = await StorageService.loadHistory();
      final categories  = await StorageService.loadCategories();
      final measurements = await MeasurementService.loadAll();
      final prefs       = await StorageService.getPrefs();
      final settings    = prefs.getString('app_settings');

      // СЧИТАЕМ СКОЛЬКО ЗАМЕРОВ ИМЕЮТ ФОТО — для статистики в диалоге
      final measurementsWithPhotos = measurements
          .where((m) => m.photoPaths.isNotEmpty)
          .length;

      // 2. УПАКОВЫВАЕМ — фото НЕ включаем, только пути (для информации)
      final measurementsMaps = measurements.map((m) {
        final map = m.toMap();
        // Очищаем пути к фото — файлы не переносятся
        // Оставляем пустой список чтобы структура не сломалась
        map['photoPaths'] = <String>[];
        map['_hadPhotos'] = m.photoPaths.length; // сколько фото было (для инфо)
        return map;
      }).toList();

      final backup = {
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'templates':    templates.map((t) => t.toMap()).toList(),
        'history':      history.map((h) => h.toMap()).toList(),
        'categories':   categories.map((c) => c.toMap()).toList(),
        'measurements': measurementsMaps,
        'settings':     settings,
        '_meta': {                                 // метаданные для диалога
          'measurementsCount': measurements.length,
          'measurementsWithPhotos': measurementsWithPhotos,
          'photosSkipped': measurementsWithPhotos > 0,
        },
      };

      // 3. ФОРМАТИРУЕМ
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      // 4. СОЗДАЁМ ФАЙЛ
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'fitflow_backup_${now.year}${_pad(now.month)}${_pad(now.day)}_'
          '${_pad(now.hour)}${_pad(now.minute)}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      // 5. ПОДЕЛИТЬСЯ
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Дневничёк — резервная копия',
        text: 'Резервная копия FitFlow от ${_formatDate(now)}',
      );

      // 6. ФОРМИРУЕМ СООБЩЕНИЕ с предупреждением о фото
      final photoWarning = measurementsWithPhotos > 0
          ? '\n⚠️ Фото из замеров ($measurementsWithPhotos записей) не включены'
          : '';

      return BackupResult.success(
        message: 'Экспорт завершён$photoWarning',
        fileName: fileName,
      );
    } catch (e) {
      return BackupResult.error('Ошибка экспорта: $e');
    }
  }

  // ИМПОРТ — читаем файл и восстанавливаем данные
  static Future<BackupResult> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Выберите файл резервной копии',
      );

      if (result == null || result.files.isEmpty) return BackupResult.cancelled();

      final path = result.files.single.path;
      if (path == null) return BackupResult.error('Не удалось прочитать файл');

      final file = File(path);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // ПРОВЕРЯЕМ ВЕРСИЮ — теперь поддерживаем 1 и 2
      final version = data['version'] as int? ?? 1;
      if (version > 2) {
        return BackupResult.error(
          'Файл создан более новой версией приложения. Обновите FitFlow.',
        );
      }

      final templatesCount   = (data['templates']    as List?)?.length ?? 0;
      final historyCount     = (data['history']       as List?)?.length ?? 0;
      final categoriesCount  = (data['categories']    as List?)?.length ?? 0;
      final measurementsCount = (data['measurements'] as List?)?.length ?? 0;
      final exportedAt       = data['exportedAt'] as String?;

      // МЕТАДАННЫЕ О ФОТО
      final meta = data['_meta'] as Map<String, dynamic>?;
      final photosSkipped = meta?['photosSkipped'] as bool? ?? false;
      final measurementsWithPhotos = meta?['measurementsWithPhotos'] as int? ?? 0;

      return BackupResult.preview(
        data: data,
        templatesCount: templatesCount,
        historyCount: historyCount,
        categoriesCount: categoriesCount,
        measurementsCount: measurementsCount,
        exportedAt: exportedAt,
        photosSkipped: photosSkipped,
        measurementsWithPhotos: measurementsWithPhotos,
      );
    } on FormatException {
      return BackupResult.error(
          'Неверный формат файла. Выберите файл резервной копии FitFlow.');
    } catch (e) {
      return BackupResult.error('Ошибка импорта: $e');
    }
  }

  // ПРИМЕНИТЬ ИМПОРТИРОВАННЫЕ ДАННЫЕ (вызывается после подтверждения пользователем)
  static Future<BackupResult> applyImport(Map<String, dynamic> data) async {
    try {
      final prefs = await StorageService.getPrefs();

      if (data['templates'] != null) {
        await prefs.setString('workout_templates', jsonEncode(data['templates']));
      }

      if (data['history'] != null) {
        await prefs.setString('workout_history', jsonEncode(data['history']));
      }

      if (data['categories'] != null) {
        final list = (data['categories'] as List)
            .map((c) => jsonEncode(c))
            .cast<String>()
            .toList();
        await prefs.setStringList('workout_categories', list); // ← исправлен ключ!
      }

      // ВОССТАНАВЛИВАЕМ ЗАМЕРЫ
      if (data['measurements'] != null) {
        await prefs.setString('measurements', jsonEncode(data['measurements']));
      }

      if (data['settings'] != null) {
        await prefs.setString('app_settings', data['settings'] as String);
      }

      return BackupResult.success(message: 'Данные восстановлены!\n'
          'Перезагрузите приложение для правильного отображения');
    } catch (e) {
      return BackupResult.error('Ошибка при восстановлении: $e');
    }
  }

  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  static String _pad (int n) => n.toString().padLeft(2, '0');

  static String _formatDate(DateTime d) =>
      '${_pad(d.day)}.${_pad(d.month)}.${d.year}';
}

// РЕЗУЛЬТАТ ОПЕРАЦИИ БЭКАПА
// Используем sealed-подобный паттерн через enum + поля
class BackupResult {
  final BackupStatus status;
  final String? message;
  final String? fileName;
  final Map<String, dynamic>? data;
  final int templatesCount;
  final int historyCount;
  final int categoriesCount;
  final int measurementsCount;
  final String? exportedAt;
  final bool photosSkipped;
  final int measurementsWithPhotos;

  const BackupResult._({
    required this.status,
    this.message,
    this.fileName,
    this.data,
    this.templatesCount = 0,
    this.historyCount = 0,
    this.categoriesCount = 0,
    this.measurementsCount = 0,
    this.exportedAt,
    this.photosSkipped = false,
    this.measurementsWithPhotos = 0,
  });

  factory BackupResult.success({required String message, String? fileName}) =>
      BackupResult._(
          status: BackupStatus.success,
          message: message,
          fileName: fileName);

  factory BackupResult.error(String message) =>
      BackupResult._(status: BackupStatus.error, message: message);

  factory BackupResult.cancelled() =>
      BackupResult._(status: BackupStatus.cancelled);

  factory BackupResult.preview({
    required Map<String, dynamic> data,
    required int templatesCount,
    required int historyCount,
    required int categoriesCount,
    int measurementsCount = 0,
    String? exportedAt,
    bool photosSkipped = false,
    int measurementsWithPhotos = 0,
  }) =>
      BackupResult._(
        status: BackupStatus.preview,
        data: data,
        templatesCount: templatesCount,
        historyCount: historyCount,
        categoriesCount: categoriesCount,
        measurementsCount: measurementsCount,
        exportedAt: exportedAt,
        photosSkipped: photosSkipped,
        measurementsWithPhotos: measurementsWithPhotos,
      );

  bool get isSuccess   => status == BackupStatus.success;
  bool get isError     => status == BackupStatus.error;
  bool get isCancelled => status == BackupStatus.cancelled;
  bool get isPreview   => status == BackupStatus.preview;
}

enum BackupStatus {success, error, cancelled, preview}
