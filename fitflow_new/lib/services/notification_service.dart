//services/notification_service.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

// СЕРВИС ДЛЯ УПРАВЛЕНИЯ УВЕДОМЛЕНИЯМИ
class NotificationService {
  // СИНГЛТОН ЭКЗЕМПЛЯР
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ПЛАГИН ДЛЯ ЛОКАЛЬНЫХ УВЕДОМЛЕНИЙ
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ИНИЦИАЛИЗАЦИЯ СЕРВИСА
  Future<void> initialize() async {
    // НАСТРОЙКИ ДЛЯ ANDROID
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // НАСТРОЙКИ ДЛЯ iOS
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // ОБЩИЕ НАСТРОЙКИ ИНИЦИАЛИЗАЦИИ
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ИНИЦИАЛИЗИРУЕМ ПЛАГИН
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // СОЗДАЕМ КАНАЛ УВЕДОМЛЕНИЙ ДЛЯ ANDROID
    await _createNotificationChannel();
  }

  // СОЗДАНИЕ КАНАЛА УВЕДОМЛЕНИЙ (только для Android)
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'workout_timer_channel',           // ID канала
      'Таймеры тренировки',       // Название канала
      description: 'Уведомления о завершении таймера отдыха', // Описание
      importance: Importance.high,     // Важность (показывать поверх других приложений)
      playSound: true,           // Воспроизводить звук
      enableVibration: true,     // Включать вибрацию
      showBadge: true,           // Показывать бейдж
      sound: RawResourceAndroidNotificationSound('timer_beep'), // Звук уведомления
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ============ ЗАПРОС РАЗРЕШЕНИЙ (iOS и Android 13+) ============
  Future<bool> requestPermissions() async {
    // ДЛЯ ANDROID 13+
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final androidGranted = await androidImplementation?.requestNotificationsPermission();

    // ДЛЯ iOS
    final iosImplementation = _notificationsPlugin
    .resolvePlatformSpecificImplementation<
    IOSFlutterLocalNotificationsPlugin>();

    final iosGranted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  // ПОКАЗАТЬ УВЕДОМЛЕНИЕ О ЗАВЕРШЕНИИ ТАЙМЕРА
  Future<void> showTimerCompleteNotification({
    required BuildContext context,
    String title = 'Таймер завершен',
    String body = 'Время отдыха истекло! Продолжайте тренировку.',
  }) async {
    try {
      // ПОЛУЧАЕМ НАСТРОЙКИ ИЗ PROVIDER
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      // ПРОВЕРЯЕМ, ВКЛЮЧЕНЫ ЛИ УВЕДОМЛЕНИЯ
      if (!settingsProvider.settings.notificationsEnabled){
        return;
      }

      // ДЕТАЛИ ДЛЯ ANDROID
      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'workout_timer_channel',         // ID канала (должен совпадать с созданным)
        'Таймер тренировки',     // Название канала
        channelDescription: 'Уведомления о таймерах тренировки',
        importance: Importance.high,     // Высокая важность
        priority: Priority.high,         // Высокий приоритет
        autoCancel: true,               // Автоматически закрывать при нажатии
        enableVibration: true,          // Включить вибрацию
        playSound: true,                // Воспроизводить звук
        timeoutAfter: 10000,
        ticker: 'Таймер завершён',
        styleInformation: DefaultStyleInformation(true, true),
      );

      // ДЕТАЛИ ДЛЯ iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,      // Показывать алерт
        presentBadge: true,      // Показывать бейдж
        presentSound: true,      // Воспроизводить звук
      );

      // ОБЩИЕ ДЕТАЛИ УВЕДОМЛЕНИЯ
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // ПОКАЗЫВАЕМ УВЕДОМЛЕНИЕ
      await _notificationsPlugin.show(
        0,                      // ID уведомления (0 для одноразовых)
        title,                 // Заголовок
        body,                  // Текст
        notificationDetails,   // Детали
      );

    } catch (_) {
    }
  }

  // ПОКАЗАТЬ УВЕДОМЛЕНИЕ О ЗАВЕРШЕНИИ ТРЕНИРОВКИ
  Future<void> showWorkoutCompleteNotification({
    required BuildContext context,
    String title = 'Тренировка завершена',
    String body = 'Отличная работа! Тренировка сохранена.',
  }) async {
    try {
      // ПОЛУЧАЕМ НАСТРОЙКИ ИЗ PROVIDER
      final settingsProvider = Provider.of<SettingsProvider>(
        context,
        listen: false,
      );

      // ПРОВЕРЯЕМ, ВКЛЮЧЕНЫ ЛИ УВЕДОМЛЕНИЯ
      if (!settingsProvider.settings.notificationsEnabled){
        return;
      }

      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'workout_timer_channel',
        'Таймеры тренировки',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        1,
        title,
        body,
        notificationDetails,
      );

    } catch (_) {
    }
  }


  // ОБРАБОТЧИК НАЖАТИЯ НА УВЕДОМЛЕНИЕ
  static void _onNotificationTapped(NotificationResponse response) {

    // ЗДЕСЬ МОЖНО ДОБАВИТЬ ЛОГИКУ ПЕРЕХОДА В ПРИЛОЖЕНИЕ
    // Например, открыть экран тренировки
  }
  // ОЧИСТИТЬ ВСЕ УВЕДОМЛЕНИЯ
  Future<void> clearAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}