//models/app_settings.dart

// МОДЕЛЬ НАСТРОЕК ПРИЛОЖЕНИЯ
class AppSettings {
  bool isDarkMode; // Темная тема
  bool soundEnabled; // Звуковые уведомления
  int defaultRestTime; // Время отдыха по умолчанию (секунды)
  bool notificationsEnabled;
  int dimAfterSeconds;
  bool dimScreenEnabled;


  AppSettings({
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.defaultRestTime = 60,
    this.notificationsEnabled = true,
    this.dimScreenEnabled = true,
    this.dimAfterSeconds = 15,
  });

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  AppSettings copyWith({
    bool? isDarkMode,
    bool? soundEnabled,
    bool? notificationsEnabled,
    bool? dimScreenEnabled,
    int? defaultRestTime,
    int? dimAfterSeconds,

  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultRestTime: defaultRestTime ?? this.defaultRestTime,
      dimAfterSeconds: dimAfterSeconds ?? this.dimAfterSeconds,
      dimScreenEnabled: dimScreenEnabled ?? this.dimScreenEnabled,
    );
  }

  // ПРЕОБРАЗОВАНИЕ В MAP
  Map<String, dynamic> toMap() {
    return {
      'isDarkMode' : isDarkMode,
      'soundEnabled' : soundEnabled,
      'defaultRestTime' : defaultRestTime,
      'notificationsEnabled' : notificationsEnabled,
      'dimAfterSeconds': dimAfterSeconds,
      'dimScreenEnabled': dimScreenEnabled,
    };
  }

  // СОЗДАНИЕ ИЗ MAP
  factory AppSettings.fromMap(Map<String, dynamic> map){
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      soundEnabled: map['soundEnabled'] ?? true,
      defaultRestTime: map['defaultRestTime'] ?? 60,
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      dimScreenEnabled: map['dimScreenEnabled'] ?? true,
      dimAfterSeconds: map['dimAfterSeconds'] ?? 15,
    );
  }

  @override
  String toString() {
    return 'AppSettings(darkMode: $isDarkMode, sound $soundEnabled, notifications: $notificationsEnabled,restTime: $defaultRestTime s)';
  }
}
