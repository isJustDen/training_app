//models/app_settings.dart

// МОДЕЛЬ НАСТРОЕК ПРИЛОЖЕНИЯ
class AppSettings {
  bool isDarkMode; // Темная тема
  bool soundEnabled; // Звуковые уведомления
  int defaultRestTime; // Время отдыха по умолчанию (секунды)
  bool notificationEnabled;

  AppSettings({
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.defaultRestTime = 60,
    this.notificationEnabled = true,
  });

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  AppSettings copyWith({
    bool? isDarkMode,
    bool? soundEnabled,
    bool? notificationEnabled,
    int? defaultRestTime,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      defaultRestTime: defaultRestTime ?? this.defaultRestTime,
    );
  }

  // ПРЕОБРАЗОВАНИЕ В MAP
  Map<String, dynamic> toMap() {
    return {
      'isDarkMode' : isDarkMode,
      'soundEnabled' : soundEnabled,
      'defaultRestTime' : defaultRestTime,
      'notificationsEnabled' : notificationEnabled,
    };
  }

  // СОЗДАНИЕ ИЗ MAP
  factory AppSettings.fromMap(Map<String, dynamic> map){
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      soundEnabled: map['soundEnabled'] ?? true,
      defaultRestTime: map['defaultRestTime'] ?? 60,
      notificationEnabled: map['notificationsEnabled'] ?? true,
    );
  }

  @override
  String toString() {
    return 'AppSettings(darkMode: $isDarkMode, sound $soundEnabled, notifications: $notificationEnabled,restTime: $defaultRestTime s)';
  }
}
