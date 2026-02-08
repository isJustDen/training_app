// main.dart
import '../services/notification_service.dart';
import 'package:flutter/material.dart';
import 'screens/templates_screen.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';


// ГЛАВНАЯ ФУНКЦИЯ
void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  try{
  // ИНИЦИАЛИЗИРУЕМ СЕРВИС УВЕДОМЛЕНИЙ
  await NotificationService().initialize();
  // ЗАПРАШИВАЕМ РАЗРЕШЕНИЯ (для Android 13+ и iOS)
  final hasPermission = await NotificationService().requestPermissions();

  if (hasPermission) {
    print('Разрешения на уведомления получены');
  } else {
    print('Разрешения на уведомления не получены');
  }
  } catch (e) {
    print('Ошибка инициализации уведомлений: $e');
  }

  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(),
          ),
        ],
      child: const WorkoutApp(),
    ),
  );
}

// КОРНЕВОЙ ВИДЖЕТ ПРИЛОЖЕНИЯ
class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context){

    // ПОЛУЧАЕМ НАСТРОЙКИ ИЗ ПРОВАЙДЕРА
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Тренировки', //Название приложения

      // ДИНАМИЧЕСКАЯ ТЕМА НА ОСНОВЕ НАСТРОЕК
      theme: ThemeData.light().copyWith(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.orange,
          surface: Colors.white,
          background: Colors.grey[50]!,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
              ),
            ),
        ),
      ),

      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[300]!,
          secondary: Colors.orange[300]!,
          surface: Colors.grey[900]!,
          background: Colors.grey[900]!,
          onPrimary: Colors.black,
          onSecondary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900]!,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.grey[800]!,
          surfaceTintColor: Colors.transparent,
        ),
        dialogBackgroundColor: Colors.grey[800]!,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[300]!,
          foregroundColor: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[300],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      themeMode: settingsProvider.settings.isDarkMode
          ? ThemeMode.dark
          : ThemeMode.light,

      home: const TemplatesScreen(), //Стартовый экран
      debugShowCheckedModeBanner: false, //убираем` лейбл DEBUG
    );
  }
}