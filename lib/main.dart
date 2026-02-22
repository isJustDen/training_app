// main.dart
import 'package:google_fonts/google_fonts.dart';

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
      title: 'FitFlow', //Название приложения
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: settingsProvider.settings.isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light,
      home: const TemplatesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─────────────────────────────────────────
// СВЕТЛАЯ ТЕМА — белая с зелёными акцентами
// ─────────────────────────────────────────
ThemeData _buildLightTheme() {
  // Базовая цветовая схема
  const seedColor = Color(0xFF2E7D52);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
    primary: const Color(0xFF2E7D52),
    onPrimary: Colors.white,
    secondary: const Color(0xFF52B788),
    onSecondary: Colors.white,
    tertiary: const Color(0xFF95D5B2),
    surface: Colors.white,
    background: const Color(0xFFF4FAF6),
    onSurface: const Color(0xFF1A1A2E),
    onBackground: const Color(0xFF1A1A2E),
    error: const Color(0xFFE53935),
    outline: const Color(0xFFB7DFC8),
  );

  final textTheme = _buildTextTheme(colorScheme.onSurface);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: colorScheme.background,

    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xFF2E7D52).withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: const Color(0xFF95D5B2).withOpacity(0.5),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: colorScheme.primary.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4FAF6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      labelStyle: GoogleFonts.nunito(color: colorScheme.primary),
      hintStyle: GoogleFonts.nunito(
        color: colorScheme.onSurface.withOpacity(0.45),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: const Color(0xFF2E7D52).withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A2E),
      ),
      contentTextStyle: GoogleFonts.nunito(
        fontSize: 14,
        color: const Color(0xFF3A3A5C),
      ),
    ),

    snackBarTheme: SnackBarThemeData(
    backgroundColor: const Color(0xFF1A1A2E),
      contentTextStyle: GoogleFonts.nunito(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
  ),

    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.tertiary.withOpacity(0.3),
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        color: colorScheme.primary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    dividerTheme: DividerThemeData(
      color: colorScheme.outline.withOpacity(0.5),
      thickness: 1,
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1A1A2E),
      ),
      subtitleTextStyle: GoogleFonts.nunito(
        fontSize: 13,
        color: const Color(0xFF6B7280),
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────────
// ТЁМНАЯ ТЕМА — тёмно-фиолетовый фон, градиентное ощущение
// ────────────────────────────────────────────────────────────
ThemeData _buildDarkTheme() {
  // Базовые цвета тёмной темы
  const bgDeep = Color(0xFF0D0D1A);
  const bgCard = Color(0xFF16162A);
  const bgElevated = Color(0xFF1E1E35);
  const accentPurple = Color(0xFF7C6FF7);
  const accentTeal = Color(0xFF56CFE1);
  const textPrimary = Color(0xFFE8E8F0);
  const textSecondary = Color(0xFF9090B0);

  final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accentPurple,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF2D2B5E),
      onPrimaryContainer: textPrimary,
      secondary: accentTeal,
      onSecondary: bgDeep,
      secondaryContainer: const Color(0xFF1A3A40),
      onSecondaryContainer: accentTeal,
      tertiary: const Color(0xFFB98EFF),
      onTertiary: bgDeep,
      surface: bgCard,
      onSurface:  textPrimary,
      background: bgDeep,
      onBackground: textPrimary,
      error: const Color(0xFFFF6B6B),
      onError: bgDeep,
      outline: const Color(0xFF3A3A5C),
      outlineVariant: const Color(0xFF252540),
      surfaceVariant: bgElevated,
      onSurfaceVariant: textSecondary,
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: textPrimary,
      onInverseSurface: bgDeep,
      inversePrimary: const Color(0xFF4B45A0),
  );

  final textTheme = _buildTextTheme(textPrimary);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: bgDeep,

    appBarTheme: AppBarTheme(
      backgroundColor: bgElevated,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.3,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: bgCard,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xFF2E7D52).withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: const Color(0xFF2E2E50),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accentPurple,
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentPurple,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF3A3A5C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF3A3A5C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accentPurple, width: 2),
      ),
      labelStyle: GoogleFonts.nunito(color: accentPurple),
      hintStyle: GoogleFonts.nunito(
        color: textSecondary.withOpacity(0.6),
      ),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: bgElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius:
      BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFF3A3A5C), width: 1),
      ),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      contentTextStyle: GoogleFonts.nunito(
        fontSize: 14,
        color: textSecondary,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: bgElevated,
      contentTextStyle: GoogleFonts.nunito(
        color: textPrimary,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xFF3A3A5C))
      ),
      behavior: SnackBarBehavior.floating,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2D2B5E),
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        color: accentPurple,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    dividerTheme: DividerThemeData(
      color: Color(0xFF2E2E50),
      thickness: 1,
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      subtitleTextStyle: GoogleFonts.nunito(
        fontSize: 13,
        color: textSecondary,
      ),
      iconColor: accentPurple,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states){
        if (states.contains(MaterialState.selected)) return accentPurple;
      }),
      trackColor: MaterialStateProperty.resolveWith((states){
        if (states.contains(MaterialState.selected)){
          return accentPurple.withOpacity(0.4);
        }
        return const Color(0xFF2E2E50);
      }),
    ),

    bottomAppBarTheme: const BottomAppBarThemeData(
      color: bgElevated,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentPurple,
      linearTrackColor: Color(0xFF2E2E50),
    ),
  );
}

// ─────────────────────────────────
// ОБЩАЯ ТИПОГРАФИКА (Nunito)
// ─────────────────────────────────

TextTheme _buildTextTheme(Color baseColor) {
  return TextTheme(
    displayLarge: GoogleFonts.nunito(
      fontSize: 32, fontWeight: FontWeight.w800, color: baseColor,
    ),
    displayMedium: GoogleFonts.nunito(
      fontSize: 28, fontWeight: FontWeight.w800, color: baseColor,
    ),
    displaySmall: GoogleFonts.nunito(
      fontSize: 24, fontWeight: FontWeight.w700, color: baseColor,
    ),
    headlineLarge: GoogleFonts.nunito(
      fontSize: 22, fontWeight: FontWeight.w700, color: baseColor,
    ),
    headlineMedium: GoogleFonts.nunito(
      fontSize: 20, fontWeight: FontWeight.w700, color: baseColor,
    ),
    headlineSmall: GoogleFonts.nunito(
      fontSize: 18, fontWeight: FontWeight.w700, color: baseColor,
    ),
    titleLarge: GoogleFonts.nunito(
      fontSize: 17, fontWeight: FontWeight.w700, color: baseColor,
    ),
    titleMedium: GoogleFonts.nunito(
      fontSize: 15, fontWeight: FontWeight.w600, color: baseColor,
    ),
    titleSmall: GoogleFonts.nunito(
      fontSize: 13, fontWeight: FontWeight.w600, color: baseColor,
    ),
    bodyLarge: GoogleFonts.nunito(
      fontSize: 15, fontWeight: FontWeight.w400, color: baseColor,
    ),
    bodyMedium: GoogleFonts.nunito(
      fontSize: 14, fontWeight: FontWeight.w400, color: baseColor,
    ),
    bodySmall: GoogleFonts.nunito(
      fontSize: 12, fontWeight: FontWeight.w400, color: baseColor.withOpacity(0.7),
    ),
    labelLarge: GoogleFonts.nunito(
      fontSize: 14, fontWeight: FontWeight.w700, color: baseColor,
    ),
    labelMedium: GoogleFonts.nunito(
      fontSize: 12, fontWeight: FontWeight.w600, color: baseColor,
    ),
    labelSmall: GoogleFonts.nunito(
      fontSize: 11, fontWeight: FontWeight.w500, color: baseColor.withOpacity(0.7),
    ),
  );
}