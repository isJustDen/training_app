//services/backup_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'storage_service.dart';


// СЕРВИС РЕЗЕРВНОГО КОПИРОВАНИЯ
// Экспортирует все данные приложения в JSON файл и импортирует обратно
class BackupService {

  // ЭКСПОРТ — собираем все данные и сохраняем в файл
  static Future<BackupResult> exportToFile () async {
    try {
      // 1. СОБИРАЕМ ВСЕ ДАННЫЕ
      final templates = await StorageService.loadTemplates();
      final history = await StorageService.loadHistory();
      final categories = await StorageService.loadCategories();
      final prefs = await StorageService.getPrefs();
      final settings = prefs.getString('app_settings');

      // 2. УПАКОВЫВАЕМ В ОДИН ОБЪЕКТ
      final backup = {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'templates': templates.map((t) => t.toMap()).toList(),
        'history': history.map((h) => h.toMap()).toList(),
        'categories': categories.map((c) => c.toMap()).toList(),
        'settings': settings,
      };

      // 3. ФОРМАТИРУЕМ КРАСИВО — с отступами, чтобы файл был читаемым
      final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

      // 4. СОЗДАЁМ ФАЙЛ
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName = 'fitflow_backup${now.year}${_pad(now.month)}${_pad(now.day)}_'
          '${_pad(now.hour)}${_pad(now.minute)}${_pad(now.second)}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonString);

      // 5. ОТКРЫВАЕМ ДИАЛОГ "ПОДЕЛИТЬСЯ"
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Дневничёк (FitFlow) - резервная копия',
        text: 'Резервная копия данных FitFlow от ${_formatDate(now)}',
      );

      return BackupResult.success(
        message: 'Экспорт завершен',
        fileName: fileName,
      );
    } catch (e) {
      return BackupResult.error('Ошибка экспорта: $e');
    }
  }

  // ИМПОРТ — читаем файл и восстанавливаем данные
  static Future<BackupResult> importFromFile() async {
    try{
      // 1. ПОЛЬЗОВАТЕЛЬ ВЫБИРАЕТ ФАЙЛ
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle:'Выберите файл резервной копии',
      );

      if (result == null || result.files.isEmpty){
        return BackupResult.cancelled();
      }

      // 2. ЧИТАЕМ ФАЙЛ
      final path = result.files.single.path;
      if (path == null) return BackupResult.error('Не удалось прочитать файл');

      final file = File(path);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // 3. ПРОВЕРЯЕМ ВЕРСИЮ ФОРМАТА
      final version = data['version'] as int? ?? 1;
      if (version>1){
        return BackupResult.error(
          'Файл создан более новой версией приложения.'
              'Обновите FitFlow.'
        );
      }

      // 4. ПОКАЗЫВАЕМ СТАТИСТИКУ ЧТО БУДЕТ ВОССТАНОВЛЕНО
      // (возвращаем данные для показа диалога подтверждения)
      final templatesCount = (data['templates'] as List?) ?.length??0;
      final historyCount = (data['history'] as List?) ?.length??0;
      final categoriesCount = (data['categories'] as List?) ?.length??0;
      final exportedAt = (data['exportedAt'] as String?);

      return BackupResult.preview(
        data: data,
        templatesCount: templatesCount,
        historyCount: historyCount,
        categoriesCount: categoriesCount,
        exportedAt: exportedAt,
      );
    } on FormatException {
      return BackupResult.error(
          'Неверный формат файла. Выберитефайл резервной копии fitflow');
    } catch (e) {
      return BackupResult.error('Ошибка импорта: $e');
    }
  }

  // ПРИМЕНИТЬ ИМПОРТИРОВАННЫЕ ДАННЫЕ (вызывается после подтверждения пользователем)
  static Future<BackupResult> applyImport(Map<String, dynamic> data) async {
    try {
      final prefs = await StorageService.getPrefs();

      // Восстанавливаем каждый тип данных
      if (data['templates'] != null) {
        final json = jsonEncode(data['templates']);
        await prefs.setString('workout_templates', json);
      }

      if (data['history'] != null) {
        final json = jsonEncode(data['history']);
        await prefs.setString('workout_history', json);
      }

      if (data['categories'] != null) {
        // Категории хранятся как List<String> — каждый элемент отдельный JSON
        final list = (data['categories'] as List)
            .map((c) => jsonEncode(c))
            .toList()
            .cast<String> ();
        await prefs.setStringList('categories', list);
      }

      if (data['settings'] != null) {
        await prefs.setString('app_settings', data['settings'] as String);
      }

      return BackupResult.success(message: 'Данные восстановлены');
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
  final String? exportedAt;

  const BackupResult._({
    required this.status,
    this.message,
    this.fileName,
    this.data,
    this.templatesCount = 0,
    this.historyCount = 0,
    this.categoriesCount = 0,
    this.exportedAt,
  });

  factory BackupResult.success({required String message, String? fileName}) =>
      BackupResult._(status: BackupStatus.success, message: message, fileName: fileName);
  factory BackupResult.error(String message) =>
      BackupResult._(status: BackupStatus.error, message: message);

  factory BackupResult.cancelled() =>
      BackupResult._(status: BackupStatus.cancelled);

  factory BackupResult.preview({
    required Map<String, dynamic> data,
    required int templatesCount,
    required int historyCount,
    required int categoriesCount,
    String? exportedAt,
  }) => BackupResult._(
      status: BackupStatus.preview,
      data: data,
      templatesCount: templatesCount,
      historyCount: historyCount,
      categoriesCount: categoriesCount,
    exportedAt: exportedAt,
  );

  bool get isSuccess => status == BackupStatus.success;
  bool get isError => status == BackupStatus.error;
  bool get isCancelled => status == BackupStatus.cancelled;
  bool get isPreview => status == BackupStatus.preview;
}

enum BackupStatus {success, error, cancelled, preview}
