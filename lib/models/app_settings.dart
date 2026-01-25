//models/app_settings.dart

// МОДЕЛЬ НАСТРОЕК ПРИЛОЖЕНИЯ
class AppSettings {
  bool isDarkMode; // Темная тема
  bool soundEnabled; // Звуковые уведомления
  int defaultRestTime; // Время отдыха по умолчанию (секунды)

  AppSettings({
    this.isDarkMode = false,
    this.soundEnabled = true,
    this.defaultRestTime = 60,
  });

  // КОПИРОВАНИЕ С ИЗМЕНЕНИЯМИ
  AppSettings copyWith({
    bool? isDarkMode,
    bool? soundEnabled,
    int? defaultRestTime,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      defaultRestTime: defaultRestTime ?? this.defaultRestTime,
    );
  }

  // ПРЕОБРАЗОВАНИЕ В MAP
  Map<String, dynamic> toMap() {
    return {
      'isDarkMode' : isDarkMode,
      'soundEnabled' : soundEnabled,
      'defaultRestTime' : defaultRestTime,
    };
  }

  // СОЗДАНИЕ ИЗ MAP
  factory AppSettings.fromMap(Map<String, dynamic> map){
    return AppSettings(
      isDarkMode: map['isDarkMode'] ?? false,
      soundEnabled: map['soundEnabled'] ?? true,
      defaultRestTime: map['defaultRestTime'] ?? 60,
    );
  }

  @override
  String toString() {
    return 'AppSettings(darkMode: $isDarkMode, sound $soundEnabled, restTime: $defaultRestTime s)';
  }
}
